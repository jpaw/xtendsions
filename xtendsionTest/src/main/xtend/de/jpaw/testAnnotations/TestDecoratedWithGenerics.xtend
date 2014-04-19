package de.jpaw.testAnnotations

import java.net.URL
import de.jpaw.annotations.Decorated

interface DemoInterfaceWithGenerics<E extends Exception> {
	def int runMethod1() throws E
	def Long compute(Long a, Long b)
	def void process1(URL z) throws E
}


class AnnoTestWithGenerics {
	@Decorated
	private DemoInterfaceWithGenerics<RuntimeException> delegator
	
	// sample for a method implemented locally
	def Long compute(Long a, Long b) {
		return a + b
	}
	
} 