/// Makes user text safe to embed in a PostgREST `.or()` / `ilike` filter.
String sanitizeSearch(String q) =>
    q.replaceAll(RegExp(r'[,()%*\\"]'), ' ').trim();
