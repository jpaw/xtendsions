package de.jpaw.testAnnotations

import java.net.URL
import de.jpaw.annotations.Decorated

interface DemoInterface {
	def int runMethod1()
	def Long compute(Long a, Long b)
	def void process1(URL z)
}


class AnnoTest {
	@Decorated
	private DemoInterface delegator
	
	// sample for a method implemented locally
	def Long compute(Long a, Long b) {
		return a + b
	}
} 