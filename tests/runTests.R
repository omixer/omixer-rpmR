# Runs the RUnit tests (runit/runit*.R; data in data/): by R CMD check, and by make testSuite. Fails when a test fails.
# The tests run in this directory, so their data paths start with data/.
library(RUnit)
library(omixerRpm)

suite <- defineTestSuite("omixerRpm", dirs = file.path(getwd(), "runit"), testFileRegexp = "^runit.+\\.R$",
                         rngKind = RNGkind()[1], rngNormalKind = RNGkind()[2])
result <- runTestSuite(suite)
printTextProtocol(result, showDetails = FALSE)

errors <- getErrors(result)
if (errors$nFail > 0 || errors$nErr > 0) {
  stop(errors$nFail, " test failures and ", errors$nErr, " test errors")
}
