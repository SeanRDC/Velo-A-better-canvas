# Documentation guide (what your docs must contain)

Your Documentation Update is graded in week 1 and again in week 2. Documentation
is not an afterthought: a reader who has never seen your app should be able to
understand what it is, get it running, and use it, from your docs alone. Keep
your documentation in your project repository's `README.md` (and link it, or a
copy, from your workspace `project/`).

Your documentation must contain these sections. Aim for clear and complete, not
long.

## 1. Overview

What the app is, in two or three sentences. What it does and who it is for.

## 2. Setup and installation

Every step to get the app running from nothing, in order:

- The Flutter and Dart versions you built with.
- How to get the code (clone).
- `flutter pub get` and any other setup.
- Any configuration the app needs (API keys, a backend URL). Never commit real
  keys; show placeholders.

## 3. How to run it

The exact command to run the app (for example `flutter run -d chrome` or a device
target) and what a reader should see when it works.

## 4. Features and usage

What the app does and how to use its main screens. Walk through the primary flow,
screen by screen.

## 5. Project structure

A short map of `lib/` and the important files, so a reader knows where the
screens, models, and state live.

## 6. Screenshots

At least one screenshot per screen the app has.

## 7. Known issues and next steps

What is not finished, what is known to be broken, and what you would do next.
Being honest here scores; pretending everything is perfect does not.

## How it is graded

See `rubrics.md` in this unit for the exact point breakdown. In short: your setup
and run steps must actually work (that is the largest share), your feature and
usage docs must match what the app really does, and screenshots plus clear
writing carry the rest.

## AI usage

Your repository must also carry an `AI-USAGE.md` and a credit line in the
README. That file is graded separately, as your finals badge, and it is worth
100 points; see the `finals-badge` unit for what goes in it. For your weekly
Documentation Update all that is checked is that the file **exists and is
current**, so start it in week 1 and keep it up as you go.