# Performance Review

## Introduce

### Github Performance Review

It helps collecting all pull requests you involved within the SESSION_START and SESSION_END.
Some determined metrics:
- Total PRs involved
- Total comments given
- The number of comments that have `suggestion` or external linking
- The number of short-form comments (> 200 chars)
- The number of long-form comments (> 500 chars)

```
Hello keymastervn
From 2021-08-02T00:00:01 to 2022-08-01T00:00:01
You've made 656 PR reviews in Thinkei with 244 comments
There are 17 comments in good quality, 16 are short-form and 4 are long-form
Keep it up, review code better 💪💪💪
```

Run it: `ruby github.rb`

## Preparation

Copy `.env.sample` to `.env`.

You may need to update the credentials there a little bit.

Then `bundle install`.

