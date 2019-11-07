${
    using Typewriter.Extensions.Types;

    Template(Settings settings)
    {
        settings
        .IncludeProject("Models.VO")
        .IncludeProject("Common")
        .OutputExtension = ".ts";
    }

    // Utilisé pour verifier qu un import n est pas fait deux fois au sein d un meme fichier
    // Il faut bien le reinitialiser apres le traitement de chaque fichier 
    static string currentFileImports="";

    void ReinitializeCurrentFileImports(File f)
    {
        currentFileImports="";
        debugInfo="";
    }

    //Retourne un log dans le fichier 
    static string debugInfo = "";
    string PrintDebugInfo(File f) {
        return debugInfo;
    }
    string PrintDebugPropertyInfo(Property f) {
        return debugInfo;
    }

    string Inherit(Class c)
    {
        if (c.BaseClass!=null)
            return "extends " + c.BaseClass.ToString() + NamespacedTypeParameters(c.BaseClass);
        else
            return  "";
    }

    string GetBasicTypeName(Type t) {
        string typeName = t.Name;
        if (t.IsGeneric && t.TypeArguments.First().IsPrimitive)
            typeName = t.Name;
        else if (typeName.EndsWith("?"))
            typeName = typeName.Substring(0, typeName.Length - 1);
        else if (typeName == "System.Object")
            typeName = "any";
        return typeName;
    }

    string GetBasicTypeNameForImport(Type t) {
        string typeName = t.Name;
        if (t.IsGeneric)
            typeName = t.Name.Substring(0,t.name.IndexOf("<"));//on supprime le type générique
        else if (typeName.EndsWith("?"))
            typeName = typeName.Substring(0, typeName.Length - 1);
        else if (typeName == "System.Object")
            typeName = "any";
        return typeName;
    }

    string NamespacedType(Type t)
    {
        if (t.IsPrimitive && !t.IsEnum)
            return t.ToString();
        if (t.IsEnumerable)
            return GetBasicTypeName(t.TypeArguments.First()) + "[]";

        string typeName = GetBasicTypeName(t);

        return typeName;
    }

    string ImportedTypeWithoutArray(Type t)
    {
        if (t.IsGeneric && t.IsEnumerable && t.OriginalName == "Dictionary")
            return GetBasicTypeNameForImport(t.TypeArguments.Skip(1).First());
        if (t.IsEnumerable)
            return GetBasicTypeNameForImport(t.TypeArguments.First());

        string typeName = GetBasicTypeNameForImport(t);

        return typeName;
    }

    string NestedNamespace(Class c) {
        return c.ContainingClass.Name;
    }

    string NamespacedTypeParameters(Class c) {
        if (c.TypeParameters.Count == 0)
            return "";
        else {
            return "<" + string.Join(", ", c.TypeArguments.Select(t => NamespacedType(t))) + ">";
        }
    }

    // Gère les imports sur les propriétés de type enum et non primitive
    // On crée une liste de lignes d imports, puis ensuite on vérifie que chaque ligne d import est unique dans le fichier courant
    string imports(Class c){
        var result= new List<string>();

        List<string> forbidden= new List<string>(){"any","T",c.Name};
        if(c.BaseClass!=null)
        {
            result.Add("import { " + c.BaseClass.ToString() + " } from './" + c.BaseClass.ToString() + "';\r\n");
            if(c.BaseClass.IsGeneric && !c.BaseClass.TypeArguments.First().IsPrimitive && !forbidden.Contains(c.BaseClass.TypeArguments.First().Name))
            {
                result.Add("import { "+c.BaseClass.TypeArguments.First().Name+" } from './"+c.BaseClass.TypeArguments.First().Name+"';\r\n");
            }
        }

        var props= c.Properties
                    .Where(x=> x.Type.Name!=c.Name
                                        && (x.Type.IsEnum
                                            ||!x.Type.IsPrimitive && (c.IsGeneric && x.Type.Name!=c.TypeParameters.First().Name)
                                            || x.Type.IsGeneric && x.Type.IsEnumerable && x.Type.OriginalName == "Dictionary"
                                                  && (!x.Type.TypeArguments.Skip(1).First().IsPrimitive || x.Type.TypeArguments.Skip(1).First().IsEnum)
                                            || !x.Type.IsPrimitive && !c.IsGeneric
                                            )
                                        && !x.Attributes.Any(a => a.Name == "TsIgnore")
                                            
                    )
                    //.Select(y=>ImportedTypeWithoutArray(y.Type))
                    .Distinct().ToArray();

        foreach(var prop in props)
        {
            if(!forbidden.Contains(prop))
            {
                var currentLine = "import { " +ImportedTypeWithoutArray(prop.Type)+" } from './";
                if( prop.Type.IsEnum || prop.Type.TypeArguments.Any(t=> t.IsEnum))
                {
                  currentLine += "enums/" + ImportedTypeWithoutArray(prop.Type) + ".enum";
                }
                else
                {
                  currentLine += ImportedTypeWithoutArray(prop.Type);
                }
                currentLine += "';\r\n";
                result.Add(currentLine);
            }
        }
        // On retire les lignes d import qui seraient deja écrites dans la classe
        result.RemoveAll(line => currentFileImports.Contains(line));
        var stringResult = string.Join(string.Empty, result);

        // Et on les ajoute a la liste des imports deja écrits
        currentFileImports += stringResult;
        return stringResult;
    }

// You access the code model by typing $ followed by a keyword e.g. $Classes which will return all public classes.
// Since $Classes is a collection of classes you also need to add a template that will be repeated for each class by adding [] after the keyword e.g. $Classes[...].
// Everything between [ and ] will be repeated for each item in the collection e.g. $Properties[public $name: $Type;].
// Primitive keywords like $Name, does not require a template.
}
/*This interface is automatically generated by the Model.tst file */
$Classes(
	   c => (c.Name.ToUpper().EndsWith("VO") 
	|| c.Name.ToUpper().EndsWith("DTO") 
	|| c.Name.EndsWith("Command")
	|| c.Name.EndsWith("Query") 
	|| c.Attributes.Any(a => a.Name == "TsClass")) && !c.Attributes.Any(a => a.Name == "TsIgnore")
)[$imports
export interface $Name$TypeParameters $Inherit{
$Properties[  $name: $Type[$NamespacedType];
]}

$NestedClasses[
	export interface $Name$TypeParameters $Inherit{
		$Properties[
			$name: $Type[$NamespacedType];]
    }
	]
]$ReinitializeCurrentFileImports
