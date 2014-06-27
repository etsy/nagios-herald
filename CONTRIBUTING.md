# Contribute

To contribute to ``nagios-herald``, you need to follow a few easy steps:

1. Fork the repo.
2. Clone your fork.
3. Hack on your favorite bits like the formatters, helpers, etc.
4. If you are adding new functionality, document it in its own file under ``docs/``.
5. If necessary, rebase your commits into logical chunks, without errors.
6. Verify your code by running the test suite, and adding additional tests if you can.
7. Push the branch up to GitHub.
8. Send a pull request.

We'll do our best to get your changes in!

## How to Run Tests

The tests are written using Ruby's minitest.

Name your tests with the ``test_`` prefix and place them in the ``test/unit/``
directory.

When you're ready to run your tests, simply run ``rake``:

```
% rake test
```

