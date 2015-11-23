package de.jpaw.annotations

import org.eclipse.xtend.lib.macro.AbstractClassProcessor
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.Visibility
import org.slf4j.Logger
import org.slf4j.LoggerFactory

@Active(AddLoggerProcessor) annotation AddLogger {}

class AddLoggerProcessor extends AbstractClassProcessor {
    
    override doTransform(MutableClassDeclaration cls, extension TransformationContext context) {
        val factory = LoggerFactory.newTypeReference
        cls.addField('LOGGER') [
            static                  = true
            final                   = true
            visibility              = Visibility.PRIVATE
            type                    = Logger.newTypeReference
            initializer             = [ '''«toJavaCode(factory)».getLogger(«cls.qualifiedName».class)''' ]
        ]
    }
}
