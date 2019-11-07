# typewriter-useful-templates
Templates and documentation to help people using this very ni(ghtmarish)ce tool. 

 

Cet article a pour but de présenter rapidement l'organisation de l'export et surtout compléter la doc mise à disposition par TypeWriter, pour clarifier quelques points obscurs ou carrément pétés.

## Présentation et installation
TypeWriter est une extension VS 2017/19. Vous pouvez l'installer aisément depuis __Extensions > Gérer les extensions__

__Son objectif est de permettre une conversion rapide et (quasiment) sans faille entre VO coté Back-End et VO coté Front-End__

Pour certains templates il faudra aussi __installer le package nuget TypeLite__ pour pouvoir utiliser l'attribut [TsIgnore] sur les classes non exportables

## Fonctionnement général
__Côté Back End__, on a nos fichiers VO, stockés dans le projet Models.VO 

__Coté Front End__, on a d'abord nos fichiers template dans le projet WebUI/ClientApp/src/models/typewriter-export/, avec l'extension .tst
Les interfaces en TypeScript seront générées autour de leur template respectif.

__Pour lancer l'export__, il suffit de sauvegarder la classe C# \*VO.cs si elle est dans le périmètre de l'outil, vous pouvez également faire clic-droit sur le fichier template (Enums.tst ou Models.tst) et selectionner __Render Template__, pour générer tous les fichiers du template. Les fichiers seront tous régénérés lorsque vous sauvegardez un fichier template.

__Les fichiers sont traités un par un <=> Un fichier \*VO.cs = 1 fichier \*Vo.ts (sauf shenanigans de maitre programmeur)__

## Composition d'un template
Un template TypeWriter est composé de deux parties : 

    ${
        using Typewriter.Extensions.Types;

        Template(Settings settings)
        {
          settings
            .IncludeProject("Models.VO")
            .IncludeProject("Models.Extracv")
            .OutputExtension = ".enum.ts";
        }
    // $Classes/Enums/Interfaces(filter)[template][separator]
    // filter (optional): Matches the name or full name of the current item. * = match any,
    // wrap in [] to match attributes or prefix with : to match interfaces or base classes.
    // template: The template to repeat for each matched item
    // separator (optional): A separator template that is placed between all templates e.g. $Properties[public $name: $Type][, ]

    // More info: http://frhagn.github.io/Typewriter/
    }/*Début fichier*/
    $Enums(
    e => e.Namespace.StartsWith("Models.")
    || e.Attributes.Any(a => a.Name == "TsEnum") && !e.Attributes.Any(a => a.Name == "TsIgnore")
    )[export const enum $Name {$Values[
    $Name = $Value,]

    }
    ]

    /*Fin fichier*/


La partie __code model__, balisée par les accolades ${ } est en C# avec de grosses feintes, __veillez à bien lire la partie Warning plus bas__

Elle contient les using, les paramètres du template (scope, output...) ces deux items sont triviaux et bien documentés sur le github. Elle contient aussi les variables globales et les méthodes d'extension. détaillées dans le fonctionnement avancé, un peu plus bas.

Des la fin de cette première partie, la partie __template__ commence, si vous mettez un retour à la ligne apres l'accolade, vos fichiers générés auront un retour a la ligne sur leur première ligne. Le template accepte le texte brut, et propose certaine méthodes qui bouclent sur des éléments donnés du fichier scanné : les classes avec $Classes( )[ ], $Enums( )[ ], $Interfaces( )[ ] ...
L'utilisation de ces méthodes est plutôt simple : on appelle la méthode $Classes et elle va générer du texte pour chaque classe contenue dans le fichier. Si on décompose l'appel d'$Enums de l'exemple ci-dessus : 

__$Enums ( Filtre ) [ Template-Elt ]__

$ __Le nom de la méthode__, il doit être préfixé d'un signe $, comme toutes les méthodes utilisées dans la partie template

() __Le filtre__, il peut s'agir d'une simple regex sur l'assembly de l'élément  → ( Application.Back.*.VO) ou bien d'un prédicat → ( c => c.Property == Value && c.Attribute.Any(a=>a.name =="test"))

[] __Le template de l’élément__, c’est le modèle qui sera répété pour chaque élément qui correspond au filtre dans votre fichier scanné.



Bien entendu il est possible d'imbriquer les templates comme suis : $Classes(filtre)[ public class $Name { $Properties(filtre)[ $name: $Type ]} ] on boucle sur les classes du fichier, pour chaque classe on boucle sur ses propriétés.



## **WARNING**
*Malgré l'aspect de certains templates qui pourrait suggérer que Typewriter parse toutes les classes de tous les fichiers, ce n'est pas le cas. __Chaque fichier est traité séparément__
Malgré le fait que chaque fichier est traité séparément, __les variable globales__ (voir prochain chapitre) __ont un périmètre qui s'étend sur l'intégralité de l'export. Elles ne s'initialisent pas au traitement de chaque fichier.__
Malgré le fait que le code model soit compilé en C#, __toute utilisation du symbole quote '  ou doubles quote " provoquera des erreurs dans le template si elle ne sont pas fermées. MÊME EN COMMENTAIRE.__ Par exemple un commentaire en français : // J'aimerai revenir corriger ce bloc plus tard provoquera une erreur, car la quote n'est pas fermée, contrairement à : // J'en peux plus c'est la merde
La meilleure solution est de __ne pas utiliser d'apostrophes ou de guillemets__ dans les commentaires.*

## Fonctionnement avancé

### Les méthodes d'extension 
En gros il y a deux types de méthodes : __les méthodes internes__, qui seront des fonctions servant à éviter la duplication et renforcer la compréhension du code par les codeurs : ci dessous la fonction NamespacedTypeParameters qui __ne peut pas être appelée directement depuis le template__ mais seulement au sein du code model. Et __les méthodes de génération de contenu__, qui elles ont au moins un argument injecté afin de __pouvoir être appelées depuis le template__.

Il est possible d'injecter un objet File, un objet Class, un objet Property selon le périmètre de la méthode, File etant le plus large.

Pour déclarer une méthode dans le __code model__, on le fait ainsi : 

   string Inherit(Class c)
   {
	   if (c.BaseClass!=null)
		   return "extends " + c.BaseClass.ToString() + NamespacedTypeParameters(c.BaseClass);
	   else
		   return "";
   }
__Pas d'accesseur pour les méthodes ( public, private...)
L'objet Class qui est en entrée est en fait injecté automatiquement. Cela signifie que la méthode peut être appelée uniquement par un objet Class ( dans un template de classe ).__

Pour appeler cette méthode de génération depuis le template on l'écrira ainsi :  export interface $Name $Inherit

La doc officielle si vous ne l'avez pas deja consultée : http://frhagn.github.io/Typewriter/pages/getting-started.html
