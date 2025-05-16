vcl 4.1;

include "backend.vcl"; // Includes backend definitions (host, port, etc.)

sub vcl_recv {
    // Remove auth and cookie headers for specific static or public API routes to enable caching
    if (
        req.url ~ "^/api/v1/custom_emojis$" ||
        req.url ~ "^/api/v(1|2)/instance$" ||
        req.url ~ "^/api/v1/instance/translation_languages$" ||
        req.url ~ "\.(css|js)$"
    ) {
        unset req.http.Authorization;
        unset req.http.Cookie;
    }

    // HTTP/2 preface method (PRI) — not valid in HTTP/1.1, return 405
    if (req.method == "PRI") {
        return (synth(405));
    }

    // In HTTP/1.1, Host header is mandatory
    if (!req.http.host &&
        req.esi_level == 0 &&
        req.proto ~ "^(?i)HTTP/1.1") {
        return (synth(400));
    }

    // Reject non-standard or CONNECT methods with pipe (pass-through)
    if (req.method != "GET" &&
        req.method != "HEAD" &&
        req.method != "PUT" &&
        req.method != "POST" &&
        req.method != "TRACE" &&
        req.method != "OPTIONS" &&
        req.method != "DELETE" &&
        req.method != "PATCH") {
        return (pipe);
    }

    // For non-GET/HEAD requests, bypass cache
    if (req.method != "GET" && req.method != "HEAD") {
        return (pass);
    }

    // Requests with Authorization or Cookie headers are not cached by default
    if (req.http.Authorization || req.http.Cookie) {
        return (pass);
    }

    // Normal cacheable request — proceed to hash lookup
    return (hash);
}

sub vcl_deliver {
    // Remove headers that expose internal Varnish details
    unset resp.http.Via;
    unset resp.http.X-Varnish;

    // Add cache hit/miss header for observability
    if (obj.hits > 0) {
        set resp.http.X-Cache = "HIT";
    } else {
        set resp.http.X-Cache = "MISS";
    }
}

sub vcl_backend_response {
    // Strip Set-Cookie headers for known cacheable URLs
    if (
        bereq.url ~ "^/api/v1/custom_emojis$" ||
        bereq.url ~ "^/api/v(1|2)/instance$" ||
        bereq.url ~ "^/api/v1/instance/translation_languages$" ||
        bereq.url ~ "\.(css|js)$"
    ) {
        unset beresp.http.set-cookie;
    }

    // If marked uncacheable, deliver directly
    if (bereq.uncacheable) {
        return (deliver);
    }
    // Treat questionable or explicitly uncacheable responses as Hit-For-Miss
    else if (beresp.ttl <= 0s ||
             beresp.http.Set-Cookie ||
             beresp.http.Surrogate-control ~ "(?i)no-store" ||
             (!beresp.http.Surrogate-Control &&
              beresp.http.Cache-Control ~ "(?i:no-cache|no-store|private)") ||
             beresp.http.Vary == "*") {
        set beresp.ttl = 120s;               // Short TTL to avoid hammering backend
        set beresp.uncacheable = true;
    }

    return (deliver); // Deliver cached or uncacheable object
}
