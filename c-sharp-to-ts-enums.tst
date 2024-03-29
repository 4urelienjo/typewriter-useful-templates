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
}$Enums(
  e => e.Namespace.StartsWith("Models.")
  || e.Attributes.Any(a => a.Name == "TsEnum") && !e.Attributes.Any(a => a.Name == "TsIgnore")
)[export const enum $Name {$Values[
  $Name = $Value,]

}
]
