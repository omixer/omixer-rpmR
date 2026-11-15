# General guidelines:

1. Add and document a test case (in tests/runit/runitModules.R, data in tests/data)
2. Implement the function until the test suite has no errors or failures. Please use `make testSuite` to run the test suite (it needs the package installed: `make install`); `R CMD check` runs it too
3. Document the function
4. Commit the changes
