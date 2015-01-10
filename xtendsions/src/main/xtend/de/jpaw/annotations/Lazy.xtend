package de.jpaw.annotations;

import org.eclipse.xtend.lib.macro.AbstractFieldProcessor
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.ClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.InterfaceDeclaration
import org.eclipse.xtend.lib.macro.declaration.MethodDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableFieldDeclaration
import org.eclipse.xtend.lib.macro.declaration.Visibility

/** Specifies the annotated field to be initialized with null, a getter created, and the initialization be performed once it is accessed.
 */
@Active(LazyProcessor)
    annotation Lazy {
}

class LazyProcessor extends AbstractFieldProcessor {

    /** returns the method if cls or one of its superclasses declares the method m, or null if no such method can be found. */
    def private MethodDeclaration getDeclaredMethod(ClassDeclaration cls, MethodDeclaration m) {
        cls.findDeclaredMethod(m.simpleName, m.parameters.map[type]) ?: (cls.extendedClass?.type as ClassDeclaration)?.getDeclaredMethod(m) 
    }
    def private void recurseInterface(InterfaceDeclaration i, MutableClassDeclaration cls, MutableFieldDeclaration f, extension TransformationContext context) {
        for (m: i.declaredMethods) {
            // check if m exists in cls or its superclasses
            val mm = cls.getDeclaredMethod(m)
            if (mm !== null) {
                if (!m.returnType.isAssignableFrom(mm.returnType))
                    mm.addWarning('''return type is incompatible to requested type «m.returnType.simpleName»''')
            } else {
                // not present, add it!
                cls.addMethod(m.simpleName) [
                    returnType = m.returnType
                    for (p: m.parameters)
                        addParameter(p.simpleName, p.type)
                    exceptions = m.exceptions
                    body = [ '''«IF m.returnType != primitiveVoid»return «ENDIF»this.«f.simpleName».«m.simpleName»(«m.parameters.map[simpleName].join(', ')»);''']
                ]
            }
        }
        for (xi: i.extendedInterfaces)
            recurseInterface(xi.type as InterfaceDeclaration, cls, f, context)
    }
    
    override doTransform(MutableFieldDeclaration field, extension TransformationContext context) {
        if (!(field.declaringType instanceof MutableClassDeclaration)) {
            field.addError("Annotation must be used within a class")
            return
        }
//        val cls = field.declaringType as MutableClassDeclaration
        if (field.type.primitive)
            field.addError("Fields with primitives are not supported by @Lazy")
    
        if (field.initializer === null)
            field.addError("A lazy field must have an initializer.")
    
        // add synthetic init-method which takes the field initializer
        field.declaringType.addMethod('_init_' + field.simpleName) [
            visibility = Visibility::PRIVATE
            returnType = field.type
            body = field.initializer
        ]

        // add a getter method which lazily initializes the field
        field.declaringType.addMethod('get' + field.simpleName.toFirstUpper) [
            returnType = field.type
            body = [ '''
                if («field.simpleName» == null) {
                    «field.simpleName» = _init_«field.simpleName»();
                    if («field.simpleName» == null)
                        throw new RuntimeException("Lazy initialization of «field.simpleName» failed");
                }
                return «field.simpleName»;
            ''' ]
        ]
    }
}
