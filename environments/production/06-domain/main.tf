module "domain" {
  source = "../../../modules/domain"

  name        = "toot.community"
  default_ttl = 3600

  records = [
    # Fastly CDN records
    { name = "@", type = "A", value = "151.101.193.91" },
    { name = "@", type = "A", value = "151.101.129.91" },
    { name = "@", type = "A", value = "151.101.65.91" },
    { name = "@", type = "A", value = "151.101.1.91" },
    { name = "@", type = "AAAA", value = "2a04:4e42:e00::347" },
    { name = "@", type = "AAAA", value = "2a04:4e42:c00::347" },
    { name = "@", type = "AAAA", value = "2a04:4e42:a00::347" },
    { name = "@", type = "AAAA", value = "2a04:4e42:800::347" },
    { name = "@", type = "AAAA", value = "2a04:4e42:600::347" },
    { name = "@", type = "AAAA", value = "2a04:4e42:400::347" },
    { name = "@", type = "AAAA", value = "2a04:4e42:200::347" },
    { name = "@", type = "AAAA", value = "2a04:4e42::347" },
    { name = "www", type = "CNAME", value = "dualstack.n.sni.global.fastly.net." },
    { name = "static", type = "CNAME", value = "dualstack.n.sni.global.fastly.net." },
    { name = "_acme-challenge.static", type = "CNAME", value = "qa6en72u2g90xtrrm2.fastly-validations.com." },
    { name = "_acme-challenge", type = "CNAME", value = "j0zavl8txaeduucvua.fastly-validations.com." },
    { name = "_acme-challenge.www", type = "CNAME", value = "qlenbedoslxxzkgx3rf.fastly-validations.com." },

    # Google
    { name = "@", type = "TXT", value = "google-site-verification=vKFUBJLyiP68EJv81ewOeD6hdd_qcBGvpe6RsIIu6a0" },

    # toot.community Services
    { name = "streaming", type = "A", value = "128.140.28.147" },
    { name = "relay", type = "A", value = "128.140.28.147" },
    { name = "tls", type = "A", value = "206.189.241.51" },
    { name = "status", type = "CNAME", value = "statuspage.betteruptime.com." },

    # GitHub Pages (Blog)
    { name = "blog", type = "CNAME", value = "toot-community.github.io." },
    { name = "_github-challenge-toot-community-org", type = "TXT", value = "f3bab071b9" },

    # Amazon SES (Outgoing Email)
    {
      name  = "2l2pnxso5mjulqkrrn3pq47pirpppeus._domainkey", type = "CNAME",
      value = "2l2pnxso5mjulqkrrn3pq47pirpppeus.dkim.amazonses.com."
    },
    {
      name  = "potvnn4g6cujc4wx5f3lo5rplctlm6sh._domainkey", type = "CNAME",
      value = "potvnn4g6cujc4wx5f3lo5rplctlm6sh.dkim.amazonses.com."
    },
    {
      name  = "opoxxgcqfzd7oot6oi3mtggu5nh6nqy3._domainkey", type = "CNAME",
      value = "opoxxgcqfzd7oot6oi3mtggu5nh6nqy3.dkim.amazonses.com."
    },
    { name = "ses", type = "MX", value = "feedback-smtp.eu-west-1.amazonses.com.", priority = 10 },
    { name = "ses", type = "TXT", value = "v=spf1 include:amazonses.com ~all" },

    # Email
    { name = "@", type = "MX", value = "in1-smtp.messagingengine.com.", priority = 10 },
    { name = "@", type = "MX", value = "in2-smtp.messagingengine.com.", priority = 20 },
    { name = "@", type = "TXT", value = "v=spf1 include:spf.messagingengine.com -all" },
    { name = "fm1._domainkey", type = "CNAME", value = "fm1.toot.community.dkim.fmhosted.com." },
    { name = "fm2._domainkey", type = "CNAME", value = "fm2.toot.community.dkim.fmhosted.com." },
    { name = "fm3._domainkey", type = "CNAME", value = "fm3.toot.community.dkim.fmhosted.com." },
  ]
}
