Set .Values.debug to true

Create secrets with: `bundle exec rails secret` (see: [here](https://github.com/mastodon/mastodon/blob/main/.env.production.sample#L43))

tootctl account create jorijn --email=jorijn@jorijn.com
tootctl account modify --role=Owner --confirm --enable jorijn --approve