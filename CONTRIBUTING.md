# Contribute

To contribute to ``nagios-herald``, you need to follow a few easy steps:

1. Fork the repo.
2. Clone your fork.
3. Run ``bundle install`` and resolve any dependency issues.
4. Hack on your favorite bits like the formatters, helpers, etc.
5. If you are adding new functionality, document it in its own file under ``docs/``.
6. If necessary, rebase your commits into logical chunks, without errors.
7. Verify your code by running the test suite, and adding additional tests if you can.
8. Push the branch up to GitHub.
9. Send a pull request.

We'll do our best to get your changes in!

## Running Tests

``rake test`` will run both the unit and integration test suites.

``rake unit_test`` runs all tests under ``test/unit``.
These tests have no external dependencies.

``rake integration_test`` runs all tests under ``test/integration``.
These tests do have external dependencies, and may need services (like mailcatcher)
to be already running before they will pass.

## Writing Tests

The tests are written using Ruby's minitest.

Match your tests to the class they're testing, name them with the ``test_`` prefix,
and place them in either the ``test/unit/`` or ``test/integration`` directories.
