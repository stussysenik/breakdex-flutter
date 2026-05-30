package com.breakdex.breakdex

import androidx.test.rule.ActivityTestRule
import dev.flutter.plugins.integration_test.FlutterTestRunner
import org.junit.Rule
import org.junit.runner.RunWith

@RunWith(FlutterTestRunner::class)
class MainActivityTest {
    @get:Rule
    val rule = ActivityTestRule(MainActivity::class.java, true, false)
}
