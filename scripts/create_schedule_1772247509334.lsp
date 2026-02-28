{
  "Uuid": "16eabf5f-6a6a-4f1a-852b-06409db11666",
  "IsCustomNode": false,
  "Description": null,
  "Name": "Create Schedule Final",
  "ElementResolver": {
    "ResolutionMap": {}
  },
  "Inputs": [
    {
      "Id": "e5c96740a32248ffa602d53ec2362943",
      "Name": "Schedule Name",
      "Type": "string",
      "Value": "",
      "Description": "Creates a string."
    },
    {
      "Id": "de94dc4457534046be6adc75f9af80e5",
      "Name": "File Path",
      "Type": "string",
      "Value": "C:\\Users\\ADMIN\\Desktop\\Book2.xlsx",
      "Description": "Allows you to select a file on the system to get its filename"
    }
  ],
  "Outputs": [],
  "Nodes": [
    {
      "ConcreteType": "CoreNodeModels.Input.StringInput, CoreNodeModels",
      "NodeType": "StringInputNode",
      "InputValue": "",
      "Id": "e5c96740a32248ffa602d53ec2362943",
      "Inputs": [],
      "Outputs": [
        {
          "Id": "d7ffd7684f85486ebac9db84049d6076",
          "Name": "",
          "Description": "String",
          "UsingDefaultValue": false,
          "Level": 2,
          "UseLevels": false,
          "KeepListStructure": false
        }
      ],
      "Replication": "Disabled",
      "Description": "Creates a string."
    },
    {
      "ConcreteType": "DSRevitNodesUI.ScheduleTypes, DSRevitNodesUI",
      "SelectedIndex": 2,
      "SelectedString": "RegularSchedule",
      "NodeType": "ExtensionNode",
      "Id": "5aa0797a008444828901512fac03f7ed",
      "Inputs": [],
      "Outputs": [
        {
          "Id": "f11036b5ad984e27b63013c128f26dba",
          "Name": "ScheduleType",
          "Description": "The selected ScheduleType",
          "UsingDefaultValue": false,
          "Level": 2,
          "UseLevels": false,
          "KeepListStructure": false
        }
      ],
      "Replication": "Disabled",
      "Description": "Select a Schedule Type."
    },
    {
      "ConcreteType": "Dynamo.Graph.Nodes.ZeroTouch.DSFunction, DynamoCore",
      "NodeType": "FunctionNode",
      "FunctionSignature": "Revit.Elements.Views.ScheduleView.CreateSchedule@Revit.Elements.Category,string,string",
      "Id": "250fe147e23f42c1aa24a92bbf2181ac",
      "Inputs": [
        {
          "Id": "dbbc666fed2b41d7947341052dff4988",
          "Name": "category",
          "Description": "Category that Schedule will be associated with.\n\nCategory",
          "UsingDefaultValue": false,
          "Level": 2,
          "UseLevels": false,
          "KeepListStructure": false
        },
        {
          "Id": "f8cc9a9094d44d8a829e2da2c7b781be",
          "Name": "name",
          "Description": "Name of the Schedule View.\n\nstring",
          "UsingDefaultValue": false,
          "Level": 2,
          "UseLevels": false,
          "KeepListStructure": false
        },
        {
          "Id": "8c49525174844f14b344053332eb8361",
          "Name": "scheduleType",
          "Description": "Type of Schedule View to be created. Ex. Key Schedule.\n\nstring",
          "UsingDefaultValue": false,
          "Level": 2,
          "UseLevels": false,
          "KeepListStructure": false
        }
      ],
      "Outputs": [
        {
          "Id": "6eb92839874745018f2e994a96da17fb",
          "Name": "scheduleView",
          "Description": "Schedule View.",
          "UsingDefaultValue": false,
          "Level": 2,
          "UseLevels": false,
          "KeepListStructure": false
        }
      ],
      "Replication": "Auto",
      "Description": "Create Schedule by Category, Type and Name.\n\nScheduleView.CreateSchedule (category: Category, name: string, scheduleType: string): ScheduleView"
    },
    {
      "ConcreteType": "Dynamo.Graph.Nodes.ZeroTouch.DSFunction, DynamoCore",
      "NodeType": "FunctionNode",
      "FunctionSignature": "Revit.Elements.Views.ScheduleView.AddFields@Revit.Schedules.SchedulableField[]",
      "Id": "a476611b834947e486cce1089c916db6",
      "Inputs": [
        {
          "Id": "49e868a9b1294cd79793585fc2999d90",
          "Name": "scheduleView",
          "Description": "Revit.Elements.Views.ScheduleView",
          "UsingDefaultValue": false,
          "Level": 1,
          "UseLevels": false,
          "KeepListStructure": false
        },
        {
          "Id": "4f25bbefb6094b4dae08d60a52ef5654",
          "Name": "fields",
          "Description": "Schedulable Field retrieved from ScheduleView.SchedulableFields.\n\nSchedulableField[]",
          "UsingDefaultValue": false,
          "Level": 1,
          "UseLevels": false,
          "KeepListStructure": false
        }
      ],
      "Outputs": [
        {
          "Id": "7a2ee8a593bd4370a6a8ee8f3d72546d",
          "Name": "scheduleView",
          "Description": "Schedule View.",
          "UsingDefaultValue": false,
          "Level": 2,
          "UseLevels": false,
          "KeepListStructure": false
        }
      ],
      "Replication": "Auto",
      "Description": "Add Field (Column) to Schedule View.\n\nScheduleView.AddFields (fields: SchedulableField[]): ScheduleView"
    },
    {
      "ConcreteType": "Dynamo.Graph.Nodes.ZeroTouch.DSFunction, DynamoCore",
      "NodeType": "FunctionNode",
      "FunctionSignature": "Revit.Elements.Views.ScheduleView.SchedulableFields",
      "Id": "d073c04f186a4cf8b480fa3b11ae51b9",
      "Inputs": [
        {
          "Id": "310dfa7f8d9f46b89c956b084405c94f",
          "Name": "scheduleView",
          "Description": "Revit.Elements.Views.ScheduleView",
          "UsingDefaultValue": false,
          "Level": 2,
          "UseLevels": false,
          "KeepListStructure": false
        }
      ],
      "Outputs": [
        {
          "Id": "b41fb1dfe7f34708bf50bc94639a21ac",
          "Name": "SchedulableField[]",
          "Description": "SchedulableField[]",
          "UsingDefaultValue": false,
          "Level": 2,
          "UseLevels": false,
          "KeepListStructure": false
        }
      ],
      "Replication": "Auto",
      "Description": "Schedulable Fields.\n\nScheduleView.SchedulableFields: SchedulableField[]"
    },
    {
      "ConcreteType": "Dynamo.Graph.Nodes.ZeroTouch.DSFunction, DynamoCore",
      "NodeType": "FunctionNode",
      "FunctionSignature": "DSCore.List.IndexOf@var[]..[],var",
      "Id": "a0aba4ba439546e4901a333b33114159",
      "Inputs": [
        {
          "Id": "c7e9abc702be442192c284f525e3dc25",
          "Name": "list",
          "Description": "The list to find the element in.\n\nvar[]..[]",
          "UsingDefaultValue": false,
          "Level": 2,
          "UseLevels": false,
          "KeepListStructure": false
        },
        {
          "Id": "8907329d7c9a48cb91a0c9c0e0d70734",
          "Name": "element",
          "Description": "The element whose index is to be returned.\n\nvar",
          "UsingDefaultValue": false,
          "Level": 2,
          "UseLevels": false,
          "KeepListStructure": false
        }
      ],
      "Outputs": [
        {
          "Id": "1b9d145eb1f54095a9df1f826edb5157",
          "Name": "int",
          "Description": "The index of the element in the list.",
          "UsingDefaultValue": false,
          "Level": 2,
          "UseLevels": false,
          "KeepListStructure": false
        }
      ],
      "Replication": "Auto",
      "Description": "Returns the index of the element in the given list.\n\nList.IndexOf (list: var[]..[], element: var): int"
    },
    {
      "ConcreteType": "Dynamo.Graph.Nodes.ZeroTouch.DSFunction, DynamoCore",
      "NodeType": "FunctionNode",
      "FunctionSignature": "DSCore.List.GetItemAtIndex@var[]..[],int",
      "Id": "eabf9bce2b214ed7a4a8d8433c371351",
      "Inputs": [
        {
          "Id": "afa83cc4ba7345c1a3be0c7e7618e629",
          "Name": "list",
          "Description": "List to fetch an item from.\n\nvar[]..[]",
          "UsingDefaultValue": false,
          "Level": 2,
          "UseLevels": false,
          "KeepListStructure": false
        },
        {
          "Id": "aae1fd81590f4d3290cf5adcfad172b9",
          "Name": "index",
          "Description": "Index of the item to be fetched.\n\nint",
          "UsingDefaultValue": false,
          "Level": 2,
          "UseLevels": false,
          "KeepListStructure": false
        }
      ],
      "Outputs": [
        {
          "Id": "f60196dabff6492eb2e74fafdccc0bc9",
          "Name": "item",
          "Description": "Item in the list at the given index.",
          "UsingDefaultValue": false,
          "Level": 2,
          "UseLevels": false,
          "KeepListStructure": false
        }
      ],
      "Replication": "Auto",
      "Description": "Returns an item from the given list that's located at the specified index.\n\nList.GetItemAtIndex (list: var[]..[], index: int): var[]..[]"
    },
    {
      "ConcreteType": "Dynamo.Graph.Nodes.ZeroTouch.DSFunction, DynamoCore",
      "NodeType": "FunctionNode",
      "FunctionSignature": "Revit.Schedules.SchedulableField.Name",
      "Id": "e8fc8a84a27a404cb3d18ff20c516db9",
      "Inputs": [
        {
          "Id": "c4ca307038ba4a97a6927122494aa63a",
          "Name": "schedulableField",
          "Description": "Revit.Schedules.SchedulableField",
          "UsingDefaultValue": false,
          "Level": 2,
          "UseLevels": false,
          "KeepListStructure": false
        }
      ],
      "Outputs": [
        {
          "Id": "9baefd3664194995b637713505838dac",
          "Name": "string",
          "Description": "string",
          "UsingDefaultValue": false,
          "Level": 2,
          "UseLevels": false,
          "KeepListStructure": false
        }
      ],
      "Replication": "Auto",
      "Description": "Name\n\nSchedulableField.Name: string"
    },
    {
      "ConcreteType": "DSRevitNodesUI.Categories, DSRevitNodesUI",
      "SelectedIndex": -1,
      "SelectedString": "",
      "NodeType": "ExtensionNode",
      "Id": "e773421e057f4b45b101712e2f157fff",
      "Inputs": [],
      "Outputs": [
        {
          "Id": "924c1f3f9fd246e3999e3deb7e188ce4",
          "Name": "Category",
          "Description": "The selected Category.",
          "UsingDefaultValue": false,
          "Level": 2,
          "UseLevels": false,
          "KeepListStructure": false
        }
      ],
      "Replication": "Disabled",
      "Description": "All built-in categories."
    },
    {
      "ConcreteType": "CoreNodeModels.Input.Filename, CoreNodeModels",
      "HintPath": "C:\\Users\\ADMIN\\Desktop\\Book2.xlsx",
      "InputValue": "C:\\Users\\ADMIN\\Desktop\\Book2.xlsx",
      "NodeType": "ExtensionNode",
      "Id": "de94dc4457534046be6adc75f9af80e5",
      "Inputs": [],
      "Outputs": [
        {
          "Id": "33e6da554e0c4f90af9f7e50c3681c52",
          "Name": "",
          "Description": "Filename",
          "UsingDefaultValue": false,
          "Level": 2,
          "UseLevels": false,
          "KeepListStructure": false
        }
      ],
      "Replication": "Disabled",
      "Description": "Allows you to select a file on the system to get its filename"
    },
    {
      "ConcreteType": "CoreNodeModels.Input.FileObject, CoreNodeModels",
      "NodeType": "ExtensionNode",
      "Id": "528f433da63a490e9e4c9e72674b2d21",
      "Inputs": [
        {
          "Id": "8ae5963c966b49c3a2f04b6738def5df",
          "Name": "path",
          "Description": "Path to the file.",
          "UsingDefaultValue": false,
          "Level": 2,
          "UseLevels": false,
          "KeepListStructure": false
        }
      ],
      "Outputs": [
        {
          "Id": "a243485be4904190bb8b8bbae7d259af",
          "Name": "file",
          "Description": "File object",
          "UsingDefaultValue": false,
          "Level": 2,
          "UseLevels": false,
          "KeepListStructure": false
        }
      ],
      "Replication": "Disabled",
      "Description": "Creates a file object from a path."
    },
    {
      "ConcreteType": "Dynamo.Graph.Nodes.CodeBlockNodeModel, DynamoCore",
      "NodeType": "CodeBlockNode",
      "Code": "\"Sheet1\";",
      "Id": "1b58626719384f9fa1149594dbee543c",
      "Inputs": [],
      "Outputs": [
        {
          "Id": "8abd4233256c4393bf996b6cf9658dcd",
          "Name": "",
          "Description": "Value of expression at line 1",
          "UsingDefaultValue": false,
          "Level": 2,
          "UseLevels": false,
          "KeepListStructure": false
        }
      ],
      "Replication": "Disabled",
      "Description": "Allows for DesignScript code to be authored directly"
    },
    {
      "ConcreteType": "Dynamo.Graph.Nodes.ZeroTouch.DSFunction, DynamoCore",
      "NodeType": "FunctionNode",
      "FunctionSignature": "DSOffice.Data.ImportExcel@var,string,bool,bool",
      "Id": "b7272c51a8414ff1b45604ec2c7fef95",
      "Inputs": [
        {
          "Id": "e0ece5a0eb2942dea44e62dd092a31e1",
          "Name": "file",
          "Description": "File representing the Microsoft Excel spreadsheet.\n\nvar",
          "UsingDefaultValue": false,
          "Level": 2,
          "UseLevels": false,
          "KeepListStructure": false
        },
        {
          "Id": "adb5ad67561d4075a12d51e113ae0984",
          "Name": "sheetName",
          "Description": "Name of the worksheet containing the data.\n\nstring",
          "UsingDefaultValue": false,
          "Level": 2,
          "UseLevels": false,
          "KeepListStructure": false
        },
        {
          "Id": "06cb68bb023c4c79a75aba3a1179408e",
          "Name": "readAsStrings",
          "Description": "Toggle to switch between reading Excel file as strings.\n\nbool\nDefault value : false",
          "UsingDefaultValue": true,
          "Level": 2,
          "UseLevels": false,
          "KeepListStructure": false
        },
        {
          "Id": "5fdd08bb30f34e1d996d2c16aa99f1be",
          "Name": "showExcel",
          "Description": "Toggle to switch between showing and hiding the main Excel window.\n\nbool\nDefault value : true",
          "UsingDefaultValue": true,
          "Level": 2,
          "UseLevels": false,
          "KeepListStructure": false
        }
      ],
      "Outputs": [
        {
          "Id": "124c717e60204c799491efce09e5bb4d",
          "Name": "data",
          "Description": "Rows of data from the Excel worksheet.",
          "UsingDefaultValue": false,
          "Level": 2,
          "UseLevels": false,
          "KeepListStructure": false
        }
      ],
      "Replication": "Auto",
      "Description": "Read data from a Microsoft Excel spreadsheet. Data is read by row and returned in a series of lists by row. Rows and columns are zero-indexed; for example, the value in cell A1 will appear in the data list at [0,0]. This node requires Microsoft Excel to be installed.\n\nData.ImportExcel (file: var, sheetName: string, readAsStrings: bool = false, showExcel: bool = true): var[][]"
    },
    {
      "ConcreteType": "Dynamo.Graph.Nodes.ZeroTouch.DSFunction, DynamoCore",
      "NodeType": "FunctionNode",
      "FunctionSignature": "DSCore.List.Transpose@var[]..[]",
      "Id": "4780f2ac088e4a898bd595307b044ddc",
      "Inputs": [
        {
          "Id": "efc4a96c80fb45b5b81adf740ad1d143",
          "Name": "lists",
          "Description": "A list of lists to be transposed.\n\nvar[]..[]",
          "UsingDefaultValue": false,
          "Level": 2,
          "UseLevels": false,
          "KeepListStructure": false
        }
      ],
      "Outputs": [
        {
          "Id": "fe21f2cb5c08423893b16c9e213086bf",
          "Name": "lists",
          "Description": "A list of transposed lists.",
          "UsingDefaultValue": false,
          "Level": 2,
          "UseLevels": false,
          "KeepListStructure": false
        }
      ],
      "Replication": "Auto",
      "Description": "Swaps rows and columns in a list of lists. If there are some rows that are shorter than others, null values are inserted as place holders in the resultant array such that it is always rectangular.\n\nList.Transpose (lists: var[]..[]): var[]..[]"
    }
  ],
  "Connectors": [
    {
      "Start": "d7ffd7684f85486ebac9db84049d6076",
      "End": "f8cc9a9094d44d8a829e2da2c7b781be",
      "Id": "05fd82e1a5e6480c8999430fb08266c4"
    },
    {
      "Start": "f11036b5ad984e27b63013c128f26dba",
      "End": "8c49525174844f14b344053332eb8361",
      "Id": "efa22a00c9b443ecad4fb1e2beada064"
    },
    {
      "Start": "6eb92839874745018f2e994a96da17fb",
      "End": "49e868a9b1294cd79793585fc2999d90",
      "Id": "8cdefc01be6f48ed968b615733a4ffc1"
    },
    {
      "Start": "6eb92839874745018f2e994a96da17fb",
      "End": "310dfa7f8d9f46b89c956b084405c94f",
      "Id": "a50c6a049fcc420f8703ecc1ddd2674e"
    },
    {
      "Start": "b41fb1dfe7f34708bf50bc94639a21ac",
      "End": "afa83cc4ba7345c1a3be0c7e7618e629",
      "Id": "3aa482d9b7f74ebabb05fd074bf5c81d"
    },
    {
      "Start": "b41fb1dfe7f34708bf50bc94639a21ac",
      "End": "c4ca307038ba4a97a6927122494aa63a",
      "Id": "e121a4032ca045d2a8a6776217a0bf8e"
    },
    {
      "Start": "1b9d145eb1f54095a9df1f826edb5157",
      "End": "aae1fd81590f4d3290cf5adcfad172b9",
      "Id": "6085587f3d4243b7bfa18357af55d0bf"
    },
    {
      "Start": "f60196dabff6492eb2e74fafdccc0bc9",
      "End": "4f25bbefb6094b4dae08d60a52ef5654",
      "Id": "8ab796dc343249a2a486fda143a3ffb5"
    },
    {
      "Start": "9baefd3664194995b637713505838dac",
      "End": "c7e9abc702be442192c284f525e3dc25",
      "Id": "53f08a6a28704a4b8893f9677cae762c"
    },
    {
      "Start": "924c1f3f9fd246e3999e3deb7e188ce4",
      "End": "dbbc666fed2b41d7947341052dff4988",
      "Id": "bb916d78836f417f9a6446744c9c983a"
    },
    {
      "Start": "33e6da554e0c4f90af9f7e50c3681c52",
      "End": "8ae5963c966b49c3a2f04b6738def5df",
      "Id": "22476deabb7241aba75a2fd411d457d8"
    },
    {
      "Start": "a243485be4904190bb8b8bbae7d259af",
      "End": "e0ece5a0eb2942dea44e62dd092a31e1",
      "Id": "3e93f57bf6fc46fa8bc6cd3106c4b07f"
    },
    {
      "Start": "8abd4233256c4393bf996b6cf9658dcd",
      "End": "adb5ad67561d4075a12d51e113ae0984",
      "Id": "11e39f00f5604133bb5d6cb39ef249ad"
    },
    {
      "Start": "124c717e60204c799491efce09e5bb4d",
      "End": "efc4a96c80fb45b5b81adf740ad1d143",
      "Id": "4257bb3960b244a98431e89300397a05"
    },
    {
      "Start": "fe21f2cb5c08423893b16c9e213086bf",
      "End": "8907329d7c9a48cb91a0c9c0e0d70734",
      "Id": "3d2ef4367aad45cbad15ba091a901dc4"
    }
  ],
  "Dependencies": [],
  "NodeLibraryDependencies": [],
  "Bindings": [],
  "View": {
    "Dynamo": {
      "ScaleFactor": 1.0,
      "HasRunWithoutCrash": true,
      "IsVisibleInDynamoLibrary": true,
      "Version": "2.5.0.7460",
      "RunType": "Manual",
      "RunPeriod": "1000"
    },
    "Camera": {
      "Name": "Default Camera",
      "EyeX": -17.0,
      "EyeY": 24.0,
      "EyeZ": 50.0,
      "LookX": 12.0,
      "LookY": -13.0,
      "LookZ": -58.0,
      "UpX": 0.0,
      "UpY": 1.0,
      "UpZ": 0.0
    },
    "NodeViews": [
      {
        "ShowGeometry": true,
        "Name": "Schedule Name",
        "Id": "e5c96740a32248ffa602d53ec2362943",
        "IsSetAsInput": true,
        "IsSetAsOutput": false,
        "Excluded": false,
        "X": 43.5745759452613,
        "Y": 423.28728797263062
      },
      {
        "ShowGeometry": true,
        "Name": "Schedule Type",
        "Id": "5aa0797a008444828901512fac03f7ed",
        "IsSetAsInput": false,
        "IsSetAsOutput": false,
        "Excluded": false,
        "X": 43.41562415221307,
        "Y": 506.4118661080978
      },
      {
        "ShowGeometry": true,
        "Name": "ScheduleView.CreateSchedule",
        "Id": "250fe147e23f42c1aa24a92bbf2181ac",
        "IsSetAsInput": false,
        "IsSetAsOutput": false,
        "Excluded": false,
        "X": 396.17175108484082,
        "Y": 377.44502084029841
      },
      {
        "ShowGeometry": true,
        "Name": "ScheduleView.AddFields",
        "Id": "a476611b834947e486cce1089c916db6",
        "IsSetAsInput": false,
        "IsSetAsOutput": false,
        "Excluded": false,
        "X": 1928.2966204591339,
        "Y": 324.68522332221812
      },
      {
        "ShowGeometry": true,
        "Name": "ScheduleView.SchedulableFields",
        "Id": "d073c04f186a4cf8b480fa3b11ae51b9",
        "IsSetAsInput": false,
        "IsSetAsOutput": false,
        "Excluded": false,
        "X": 686.98272624500771,
        "Y": 546.71387531190226
      },
      {
        "ShowGeometry": true,
        "Name": "List.IndexOf",
        "Id": "a0aba4ba439546e4901a333b33114159",
        "IsSetAsInput": false,
        "IsSetAsOutput": false,
        "Excluded": false,
        "X": 1484.8037933904925,
        "Y": 614.60833174046638
      },
      {
        "ShowGeometry": true,
        "Name": "List.GetItemAtIndex",
        "Id": "eabf9bce2b214ed7a4a8d8433c371351",
        "IsSetAsInput": false,
        "IsSetAsOutput": false,
        "Excluded": false,
        "X": 1695.6176641185589,
        "Y": 494.00149547377146
      },
      {
        "ShowGeometry": true,
        "Name": "SchedulableField.Name",
        "Id": "e8fc8a84a27a404cb3d18ff20c516db9",
        "IsSetAsInput": false,
        "IsSetAsOutput": false,
        "Excluded": false,
        "X": 1051.4203714683647,
        "Y": 659.23634249988027
      },
      {
        "ShowGeometry": true,
        "Name": "Categories",
        "Id": "e773421e057f4b45b101712e2f157fff",
        "IsSetAsInput": true,
        "IsSetAsOutput": false,
        "Excluded": false,
        "X": 46.081553180931564,
        "Y": 326.25284872256094
      },
      {
        "ShowGeometry": true,
        "Name": "File Path",
        "Id": "de94dc4457534046be6adc75f9af80e5",
        "IsSetAsInput": true,
        "IsSetAsOutput": false,
        "Excluded": false,
        "X": 116.54455177367697,
        "Y": 834.42516948171419
      },
      {
        "ShowGeometry": true,
        "Name": "File From Path",
        "Id": "528f433da63a490e9e4c9e72674b2d21",
        "IsSetAsInput": false,
        "IsSetAsOutput": false,
        "Excluded": false,
        "X": 457.80632052963722,
        "Y": 823.6452165871832
      },
      {
        "ShowGeometry": true,
        "Name": "Code Block",
        "Id": "1b58626719384f9fa1149594dbee543c",
        "IsSetAsInput": false,
        "IsSetAsOutput": false,
        "Excluded": false,
        "X": 448.610558880579,
        "Y": 927.70011647836418
      },
      {
        "ShowGeometry": true,
        "Name": "Data.ImportExcel",
        "Id": "b7272c51a8414ff1b45604ec2c7fef95",
        "IsSetAsInput": false,
        "IsSetAsOutput": false,
        "Excluded": false,
        "X": 690.80632052963722,
        "Y": 803.6452165871832
      },
      {
        "ShowGeometry": true,
        "Name": "List.Transpose",
        "Id": "4780f2ac088e4a898bd595307b044ddc",
        "IsSetAsInput": false,
        "IsSetAsOutput": false,
        "Excluded": false,
        "X": 1106.0602370520032,
        "Y": 812.32388839516466
      }
    ],
    "Annotations": [],
    "X": -6.0033062060749671,
    "Y": -92.661970201991153,
    "Zoom": 0.76261590282203606
  }
}