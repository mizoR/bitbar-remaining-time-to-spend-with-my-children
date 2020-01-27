# bitbar-remaining-time-to-spend-with-my-children

BitBar plugin to show remaining time to spend with your children

<img width="371" src="https://user-images.githubusercontent.com/1257116/73133798-14a41080-4071-11ea-941f-f0f3d3a9d70f.png">

## Configuration

`~/.bitbarrc` example:

```ini
[remaining_time_to_spend_with_my_children]

;# Required
child_identifiers = child0,child1

child0_label            = ":girl:"
child0_birthday         = "2014-07-10+09:00"
child0_independence_day = "2032-04-01+09:00"

child1_label            = ":baby:"
child1_birthday         = "2019-12-01+09:00"
child1_independence_day = "2037-04-01+09:00"

;# Optional
hours_a_day_during_infant             = 7
hours_a_day_during_elementary         = 6
hours_a_day_during_junior_high_school = 4
hours_a_day_during_high_school        = 3
hours_a_day_during_college_or_later   = 2

;# You can customize text color - (Default: black)
text_color = "white"
```
