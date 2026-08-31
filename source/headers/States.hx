package headers;

// REFACTOR: categorization header re-exporting the states.helpers group
typedef FreeplayStateHelpers = states.helpers.FreeplayStateHelpers;
#if MODS_ALLOWED
typedef ModsMenuHelpers = states.helpers.ModsMenuHelpers;
#end
typedef GameplayChangersHelpers = states.helpers.GameplayChangersHelpers;