# Reflection Journal

## Week of: September 28, 2026 to October 6, 2026

## My goal this week
My goal was to take Velo from a set of built screens to a finished, deployed app. That meant finishing the To do screen, building the Planner hub and wiring the AI into it, making the AI Assistant answer from my real Canvas data, replacing everything that was still simulated (the login and the assignment submission), and publishing the app to the web so it can be opened from a link instead of being cloned.

## What I did
I finished the To do screen (formerly the Dashboard) with an overdue, due today and this week summary, and put the course image on every task card so courses are easy to tell apart. I built the Planner hub with daily milestones and added an Auto-Plan button that asks the AI to spread upcoming work across the days before each deadline. I replaced Gemini with Groq and moved the AI Assistant to function calling, giving it tools for pending tasks, grades, announcements, inbox messages and assignment details, then added chat suggestions, clickable in-app links and a typing bubble.

I replaced the simulated login with a real sign-in using a Canvas access token and synced the Account screen with my live Canvas profile, including bio editing. I made assignment submission real, so file uploads, text entries and website URLs now reach Canvas, and added the submission comment thread. I also added pull to refresh on every data screen, a last-synced time on the offline banner, a prompt to go back online when the connection returns, deadline reminders with adjustable timing, and a responsive layout with a pinned side drawer for tablet and desktop.

Finally, I deployed the app on Vercel as an installable PWA with app icons, redesigned the login, To do, Courses and Inbox screens, and completed the final documentation, the AI-USAGE record and the presentation video.

## What blocked me
The AI Assistant kept hitting Gemini's free-tier rate limits because every message carried the full course context. I resolved it by switching to Groq and to function calling, so the model only requests the data it needs, plus a short cooldown between messages.

Once the app ran in a browser, every Canvas API call was blocked by CORS. I resolved it by routing the requests through a Vercel rewrite. Canvas OAuth also turned out to need a developer key issued by the school's Canvas administrator, which I do not have, so I reversed my Week 1 decision and used a token the student generates themselves.

I also hit errors from `setState` being called after a screen was closed during slow network calls, which I fixed by adding `mounted` checks across the data screens, and I found that my submit button only simulated a submission and never reached Canvas, so I implemented the real submission and file upload endpoints. After deploying, I found that the Groq key was bundled into the web build where a visitor could read it, so I moved it into a serverless function on Vercel.

## What I learned
I learned that giving an AI model tools is better than giving it everything. Splitting my Canvas context into small functions kept each request small, stayed inside the rate limits, and made the answers come from current data instead of one large prompt.

I learned that deploying to the web changes the rules. Things that worked while I was developing, such as calling Canvas directly or reading an API key from `.env`, either get blocked by the browser or become readable by anyone who opens the site. Anything secret has to stay on a server, and a proxy is needed for an API that was not built to be called from a browser.

I also learned to check a plan against what I can actually get access to. I committed to OAuth in Week 1 because it matched the mockups, without knowing it depended on a key only the school can issue. And I learned that a feature that only looks finished is not finished: the simulated login and submit button both had to be rebuilt before the app was really usable.
