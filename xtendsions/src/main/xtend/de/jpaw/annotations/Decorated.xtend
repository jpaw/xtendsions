package de.jpaw.annotations;

import org.eclipse.xtend.lib.macro.declaration.ClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.Active
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import org.eclipse.xtend.lib.macro.AbstractFieldProcessor
import org.eclipse.xtend.lib.macro.declaration.MutableFieldDeclaration
import org.eclipse.xtend.lib.macro.declaration.InterfaceDeclaration
import org.eclipse.xtend.lib.macro.declaration.MethodDeclaration

/** Specifies the annotated field to be a reference to a decorated class.
 * The effect of this active Annotation is to generate delegating methods for all method signatures which do not yet exist.
 * Errors are generated if a method exists, but has an incompatible return type.
 */
@Active(DecoratedProcessor)
    annotation Decorated {
}

class DecoratedProcessor extends AbstractFieldProcessor {
    private static final Logger logger = LoggerFactory::getLogger(DecoratedProcessor)

    def static void logme(CharSequence x) {
        System::out.println(x.toString)
        logger.info(x.toString)
    }

    /** returns the method if cls or one of its superclasses declares the method m, or null if no such method can be found. */
    def private MethodDeclaration getDeclaredMethod(ClassDeclaration cls, MethodDeclaration m) {
        cls.findDeclaredMethod(m.simpleName, m.parameters.map[type]) ?: (cls.extendedClass?.type as ClassDeclaration)?.getDeclaredMethod(m) 
    }
    def private void recurseInterface(InterfaceDeclaration i, MutableClassDeclaration cls, MutableFieldDeclaration f, extension TransformationContext context) {
        for (m: i.declaredMethods) {
            // check if m exists in cls or its superclasses
            val mm = cls.getDeclaredMethod(m)
            if (mm != null) {
                if (!m.returnType.isAssignableFrom(mm.returnType))
                    mm.addWarning('''return type is incompatible to requested type «m.returnType.simpleName»''')
            } else {
	            // not present, add it!
	            cls.addMethod(m.simpleName) [
	                returnType = m.returnType
	                for (p: m.parameters)
	                    addParameter(p.simpleName, p.type)
	                body = [ '''«IF m.returnType != primitiveVoid»return «ENDIF»this.«f.simpleName».«m.simpleName»(«m.parameters.map[simpleName].join(', ')»);''']
	            ]
            }
        }
        for (xi: i.extendedInterfaces)
            recurseInterface(xi.type as InterfaceDeclaration, cls, f, context)
    }
    
    override doTransform(MutableFieldDeclaration f, extension TransformationContext context) {
        logme('''Called doTransform for Decorated: field «f.simpleName»''')
        
        if (!(f.declaringType instanceof MutableClassDeclaration)) {
            f.addError("Annotation must be used within a class")
            return
        }
        val cls = f.declaringType as MutableClassDeclaration
        
        if (f.type.type instanceof InterfaceDeclaration) {
            f.addWarning("Is an Interface")
            recurseInterface(f.type.type as InterfaceDeclaration, cls, f, context)
        } else if (f.type.type instanceof ClassDeclaration) {
            f.addWarning("Is a class")
        } else {
            f.addError("Annotated field must be a class or an interface")
        }
    }
}
