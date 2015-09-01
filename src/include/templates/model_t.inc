#if defined _model_t_included
    #endinput
#endif
#define _model_t_included

/**
 * Definition to permit the MDL tag in place of the Model tag.
 */
#define MDL: Model:

/**
 * Defines the maximum length for the name field of a model
 */
#define model_Name_length 31

/**
 * Defines the maximum length for the path field of a model
 */
#define model_Path_length 127

/**
 * Constant representing the value used for a model which is invalid.
 */
enum Model {
    Invalid_Model
};

/**
 * Represents a template for a model.
 */
enum model_t {
    /**
     * Name of this model
     */
    model_Name[model_Name_length+1],

    /**
     * The number of cells within {@link #model_Name} that are filled
     */
    model_NameLength,

    /**
     * Path of this model
     */
    model_Path[model_Path_length+1],

    /**
     * The number of cells within {@link #model_Path} that are filled
     */
    model_PathLength,
};

#define getModelName(%1)\
    %1[model_Name]

#define getModelNameLength(%1)\
    %1[model_NameLength]

#define getModelPath(%1)\
    %1[model_Path]

#define getModelPathLength(%1)\
    %1[model_PathLength]