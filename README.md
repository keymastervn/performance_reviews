# Performance Review

## Introduce

### Github Performance Review

Collect all pull requests you involved within the SESSION_START and SESSION_END.
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

### Confluence Performance Review

Collect all confluence pages created by you within the SESSION_START and SESSION_END.
Some determined metrics:
- Total number of pages
- Total likes of those pages

```
Hello keymastervn
From 2021-08-02T00:00:01 to 2022-08-01T00:00:01
You've made 70 confluence pages with total 70 likes
> The most liked page is Benchmark and Profilling Ruby with 6 likes
Keep it up, write more proposals or knowledge pages 📝✍️
```

Misc: if you are such a lazy guy and you like unix tool parsing

```
curl -u dat.le@your_company.com:your_token -G "https://your_company.atlassian.net/wiki/rest/api/content/search" \
--data-urlencode "cql=(type=page and creator=currentUser() and created >= 2021-08-01 and created <= 2022-08-01)" \
--data-urlencode "limit=1000" \
--data-urlencode "expand=metadata.properties,metadata.likes,history" | jq .
```

if not, run `ruby confluence.rb`

## Preparation

Copy `.env.sample` to `.env`.

You may need to update the credentials there a little bit.

Then `bundle install`.

