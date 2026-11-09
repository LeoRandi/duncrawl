## Cambiar el tipo de dato de un campo en SQLite
En el DAO, en la lista de updateScripts se deben añadir los siguientes Script, adaptados a esa tabla específica.
       
        "ALTER TABLE [$dbTableName] RENAME TO [${dbTableName}_temp];",
        this.createTableScripts[0],
        """
        INSERT INTO [$dbTableName]([$dbCampo1], [$dbCampo2])
        SELECT [$dbCampo1], [$dbCampo2]
        FROM [${dbTableName}_temp];
    """,
        "DROP TABLE [${dbTableName}_temp];"

# Ver de dónde viene un permiso de manifest al compilar

The manifest you see in your source is not the one that's in the final APK. The final AndroidManifest gets built up through the build process and compiled from different sources. If you'd like to see a full report of the manifest merging you can go into

build/app/outputs/logs

This is a very long log report, but you can read where all the manifest parts are coming from. If you'd like to see the final manifest itself this can be found in

build/app/intermediates/manifests/full/release or 
build/app/intermediates/manifests/full/debug

This won't let you know where it's from, but you can look at the permissions and do a search in your build folder and you should find the partial manifest generated somewhere and you can see where exactly it's coming from.