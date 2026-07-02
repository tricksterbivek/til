# TIL: no LIMIT, use FETCH

NetSuite SuiteQL uses `FETCH FIRST n ROWS ONLY` instead of `LIMIT n`.
