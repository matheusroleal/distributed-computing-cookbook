struct { name = "minhaStruct",
         fields = {{name = "nome",
                    type = "string"},
                   {name = "peso",
                    type = "double"},
                   {name = "idade",
                    type = "int"},
                   }
       }
interface { name = "minhaInt",
            methods = {
               foo = {
                 resulttype = "double",
                 args = {{direction = "in",
                          type = "double"},
                         {direction = "in",
                          type = "string"},
                         {direction = "in",
                          type = "minhaStruct"},
                         {direction = "in",
                          type = "int"}
                        }
               },
               boo = {
                 resulttype = "void",
                 args = {{direction = "in",
                          type = "double"},
                         {direction = "out",
                          type = "minhaStruct"}
                        }
               }
             }
            }