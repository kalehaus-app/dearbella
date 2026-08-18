#!/usr/bin/env python3
"""Create (or inspect) the Dear Bella feedback form via the Tally API.

Usage:

    export TALLY_API_KEY='your key from tally.so/settings/api'

    # 1. Check the key works and list what's already there.
    python3 scripts/tally_feedback_form.py list

    # 2. Dump one form's blocks — this is ground truth for the JSON shape.
    python3 scripts/tally_feedback_form.py probe <form-id>

    # 3. Print the payload without sending it.
    python3 scripts/tally_feedback_form.py create --dry-run

    # 4. Actually create it.
    python3 scripts/tally_feedback_form.py create

The key is read from the environment and is never written to disk or printed.
"""

import argparse
import json
import os
import sys
import urllib.error
import urllib.request
import uuid

API = "https://api.tally.so"

# Tally sits behind Cloudflare, which rejects urllib's default
# "Python-urllib/3.x" signature with a 403 (error code 1010) before the
# request ever reaches the API. A normal browser User-Agent gets through.
BROWSER_UA = (
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
    "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
)


# --------------------------------------------------------------------------
# HTTP
# --------------------------------------------------------------------------

def call(method, path, body=None):
    key = os.environ.get("TALLY_API_KEY")
    if not key:
        sys.exit("TALLY_API_KEY is not set. Get one at tally.so/settings/api, then:\n"
                 "  export TALLY_API_KEY='...'")

    data = json.dumps(body).encode() if body is not None else None
    request = urllib.request.Request(
        f"{API}{path}",
        data=data,
        method=method,
        headers={
            "Authorization": f"Bearer {key}",
            "Content-Type": "application/json",
            "Accept": "application/json",
            "User-Agent": BROWSER_UA,
        },
    )

    try:
        with urllib.request.urlopen(request) as response:
            raw = response.read().decode()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as error:
        detail = error.read().decode()
        print(f"\nHTTP {error.code} from {method} {path}", file=sys.stderr)
        print(detail or "(no body)", file=sys.stderr)

        if "1010" in detail or "cloudflare" in detail.lower():
            print("\nThat is Cloudflare blocking the request, not Tally "
                  "rejecting the key. Try the curl fallback in the README "
                  "section of this file.", file=sys.stderr)
        elif error.code in (401, 403):
            print("\nCheck TALLY_API_KEY is set and still valid "
                  "(tally.so -> Settings -> API).", file=sys.stderr)
        else:
            print("\nPaste the above back into the chat and the payload can "
                  "be corrected to match.", file=sys.stderr)
        sys.exit(1)


# --------------------------------------------------------------------------
# Block builders
#
# Tally models a form as a flat list of blocks. A question is not one block:
# it is a title block plus one block per option, tied together by a shared
# groupUuid. These four helpers are the only place that shape is encoded, so
# if the API rejects the payload, the fix belongs here and nowhere else.
# --------------------------------------------------------------------------

# Blocks that collect an answer. Only these carry the positional flags below;
# layout blocks (FORM_TITLE, TITLE, TEXT, HIDDEN_FIELDS) reject them outright.
QUESTION_TYPES = {
    "INPUT_TEXT", "TEXTAREA", "INPUT_EMAIL", "INPUT_NUMBER", "INPUT_LINK",
    "INPUT_PHONE_NUMBER", "INPUT_DATE", "INPUT_TIME",
    "MULTIPLE_CHOICE_OPTION", "CHECKBOX", "DROPDOWN_OPTION",
    "RATING", "LINEAR_SCALE", "RANKING",
}


def new_uuid():
    return str(uuid.uuid4())


def normalize(blocks):
    """Stamps each answer block's position within its group.

    A question is a title block plus one block per option sharing a groupUuid,
    and Tally uses these flags to know where one question's options end and the
    next question begins. They belong only on the blocks that collect an
    answer — layout blocks reject them as unknown fields — so the type is
    checked before stamping. Deriving the flags from the assembled list means
    the builders below never track position by hand, and a question that is a
    single block correctly gets both.
    """
    for index, current in enumerate(blocks):
        if current["type"] not in QUESTION_TYPES:
            continue
        previous = blocks[index - 1]["groupUuid"] if index > 0 else None
        following = blocks[index + 1]["groupUuid"] if index < len(blocks) - 1 else None
        current["payload"]["isFirst"] = current["groupUuid"] != previous
        current["payload"]["isLast"] = current["groupUuid"] != following
    return blocks


def block(type_, payload, group_uuid, group_type):
    return {
        "uuid": new_uuid(),
        "type": type_,
        "groupUuid": group_uuid,
        "groupType": group_type,
        "payload": payload,
    }


def question_title(text):
    """The label above a question. Its groupType must be TITLE — TEXT is only
    for standalone prose like the form's description."""
    return block("TITLE", {"safeHTMLSchema": [[text]]}, new_uuid(), "TITLE")


def heading(title, subtitle=None):
    """The form's name comes from its first block, which must be FORM_TITLE."""
    group = new_uuid()
    blocks = [block("FORM_TITLE", {"title": title}, group, "TEXT")]
    if subtitle:
        group = new_uuid()
        blocks.append(block("TEXT", {"safeHTMLSchema": [[subtitle]]}, group, "TEXT"))
    return blocks


def choice_question(title, options, multiple=False, required=True):
    """A single- or multi-select question: one title block, then one block
    per option, all sharing the option group's uuid."""
    option_group = new_uuid()
    option_type = "CHECKBOXES" if multiple else "MULTIPLE_CHOICE"
    block_type = "CHECKBOX" if multiple else "MULTIPLE_CHOICE_OPTION"

    blocks = [question_title(title)]
    for option in options:
        blocks.append(block(
            block_type,
            {"index": options.index(option), "text": option, "isRequired": required},
            option_group,
            option_type,
        ))
    return blocks


def text_question(title, *, long=True, required=False, placeholder=None):
    input_group = new_uuid()
    input_type = "TEXTAREA" if long else "INPUT_TEXT"

    payload = {"isRequired": required}
    if placeholder:
        payload["placeholder"] = placeholder

    return [
        question_title(title),
        block(input_type, payload, input_group, input_type),
    ]


def email_question(title, required=False):
    input_group = new_uuid()
    return [
        question_title(title),
        block("INPUT_EMAIL", {"isRequired": required}, input_group, "INPUT_EMAIL"),
    ]


def hidden_fields(*names):
    """Lets the app tag responses with where they came from (?source=ios),
    so in-app answers can be told apart from ones shared elsewhere.

    All hidden fields live in a single block, as one list — they are form
    configuration rather than something the respondent sees, so there is no
    per-field block the way there is for options.
    """
    group = new_uuid()
    fields = [{"uuid": new_uuid(), "name": name} for name in names]
    return [block("HIDDEN_FIELDS", {"hiddenFields": fields}, group, "HIDDEN_FIELDS")]


# --------------------------------------------------------------------------
# The survey
# --------------------------------------------------------------------------

def build_form():
    blocks = []

    blocks += heading(
        "Help shape Dear Bella",
        "6 quick questions, about 2 minutes. Every answer goes straight into "
        "what gets built next.",
    )

    blocks += hidden_fields("source")

    # Habit — tests whether this really is a weekend product.
    blocks += choice_question(
        "How often do you open Dear Bella?",
        ["Most days",
         "A few times a week",
         "Mainly on weekends",
         "Every couple of weeks",
         "This is my first time"],
    )

    # Which of the four entry points actually earns its keep.
    blocks += choice_question(
        "When you're deciding what to watch, where do you usually start?",
        ["Ask Bella in chat",
         "Swipe through films",
         "Play a bracket",
         "Bella's daily pick",
         "Just browse my list"],
    )

    # Behaviour, not opinion — the real measure of recommendation quality.
    blocks += choice_question(
        "Have you actually watched something Dear Bella suggested?",
        ["Yes, and I loved it",
         "Yes, it was fine",
         "Yes, but it wasn't for me",
         "Not yet"],
    )

    # The Sean Ellis product-market-fit question. 40%+ "very disappointed"
    # is the conventional threshold for having found fit.
    blocks += choice_question(
        "How would you feel if you could no longer use Dear Bella?",
        ["Very disappointed",
         "Somewhat disappointed",
         "Not disappointed"],
    )

    blocks += text_question(
        "What's the one thing that would make Dear Bella more useful to you?",
        placeholder="Anything at all — the smaller and more specific, the better.",
    )

    # Roadmap bets made to compete with each other, plus an honest opt-out.
    blocks += choice_question(
        "Which of these would you actually use?",
        ["TV shows, not just films",
         "Seeing what friends are watching",
         "Knowing where to stream each film",
         "Reminders about films I saved",
         "Notes and ratings on what I've watched",
         "None of these"],
        multiple=True,
        required=False,
    )

    blocks += text_question("Anything else you want to tell us?", required=False)

    blocks += email_question(
        "Email (optional) — only if you'd like us to follow up, or to hear "
        "when Friends launches."
    )

    return {"status": "PUBLISHED", "blocks": normalize(blocks)}


# --------------------------------------------------------------------------
# Commands
# --------------------------------------------------------------------------

def cmd_list(_args):
    forms = call("GET", "/forms")
    items = forms.get("items", forms if isinstance(forms, list) else [])
    if not items:
        print("No forms yet. The key works, though.")
        return
    for form in items:
        print(f"{form.get('id')}  {form.get('status', ''):10}  {form.get('name')}")


def cmd_probe(args):
    """Dumps a form's real block JSON — ground truth for the schema above."""
    print(json.dumps(call("GET", f"/forms/{args.form_id}"), indent=2))


def cmd_create(args):
    payload = build_form()
    if args.dry_run:
        print(json.dumps(payload, indent=2))
        return

    form = call("POST", "/forms", payload)
    form_id = form.get("id")
    print("\nCreated.\n")
    print(f"  id:    {form_id}")
    print(f"  name:  {form.get('name')}")
    print(f"  edit:  https://tally.so/forms/{form_id}/edit")
    print(f"  share: https://tally.so/r/{form_id}")
    print("\nSend the share URL back to the chat to have it wired into the app.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("list", help="list forms (also verifies the API key)")

    probe = sub.add_parser("probe", help="dump one form's blocks as JSON")
    probe.add_argument("form_id")

    create = sub.add_parser("create", help="create the feedback form")
    create.add_argument("--dry-run", action="store_true",
                        help="print the payload instead of sending it")

    args = parser.parse_args()
    {"list": cmd_list, "probe": cmd_probe, "create": cmd_create}[args.command](args)


if __name__ == "__main__":
    main()
