# Future Features

Ideas intentionally postponed until after version 1.5.

This is **not** a roadmap and **not** an implementation plan. Items here are collected for later evaluation only.

> A feature should not move from this document into implementation until its product behavior is clearly defined and it remains consistent with the project's design philosophy.

---

## Learning Perspective

| | |
|--|--|
| **Title** | Learning Perspective |
| **Motivation** | Help users understand the scale of their accumulated learning time through interesting real-world comparisons. |
| **User value** | Turns abstract hour totals into memorable analogies, reinforcing progress without changing how time is tracked. |
| **Complexity** | Low |
| **Risk** | Low — presentation-only; wrong or culturally sensitive analogies could feel gimmicky if copy is not curated carefully. |
| **Notes** | Pure presentation layer. Uses already calculated lifetime hours. No database changes. No tracking changes. No additional persistence. Comparison thresholds can be stored in a static table. Display the largest comparison whose required time is less than or equal to the user's accumulated time. Ignore sub-minute comparisons because the application's smallest unit is one minute. |
| **Status** | Idea |

Illustrative comparisons only (not an implementation list):

- Light reaches the Moon.
- Light reaches the Sun.
- Light reaches Neptune.
- One light-year.
- Number of average books that could be read.
- Approximate university semesters.
- Flights around Earth.

#### Open Questions

- Should comparisons be astronomy only?
- Or combine astronomy, education and everyday life?
- Should the UI display only the best matching comparison or multiple comparisons?
- Should users be able to disable this section?

---

## Emoji Picker

| | |
|--|--|
| **Title** | Emoji Picker |
| **Motivation** | Allow users to quickly add a meaningful emoji to a Skill without leaving the application. |
| **User value** | Faster personalization of skill names; clearer visual scanning in lists without relying on SF Symbols or photos. |
| **Complexity** | Low |
| **Risk** | Low–Medium — must avoid private keyboard APIs; a custom list may feel less complete than the system emoji keyboard. |
| **Notes** | Small curated emoji list. No private iOS APIs. No custom keyboard. No search. No categories required for first version. Simple SwiftUI sheet. Emoji inserted into the Skill name. |
| **Status** | Idea |

#### Priority

High

#### Open Questions

- Insert emoji at the beginning or end of the Skill name?
- Allow removing the emoji with one tap?
- Keep a single curated list or group emoji into simple categories?

---

## Signed Time Entries

| | |
|--|--|
| **Title** | Signed Time Entries |
| **Motivation** | Treat `TimeIntervalEntry` as a complete history of time changes instead of only recorded sessions. |
| **User value** | Correct history, better exports, future Undo support, and more accurate statistics. |
| **Complexity** | Medium |
| **Risk** | Medium |
| **Priority** | Medium |
| **Notes** | Store manual corrections with their real positive or negative value. Introduce future entry classification (`tracked`, `manual`, `correction`). Session-length distributions should ignore correction entries while lifetime totals continue to reflect the accumulated result. |
| **Status** | Idea |

---

## Design Philosophy

Future features should:

- not complicate the tracking model,
- not introduce unnecessary background processing,
- prefer simple solutions,
- preserve the existing architecture whenever possible.
