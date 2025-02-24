echo "Build library"
chmod +x ./gradlew
rm -Rf binding/xamarin
./gradlew xamarin

echo "Recreating Android.Binding/aars/ and Android.Binding/jars/"
AARS_DIR="../Android.Binding/aars"
JARS_DIR="../Android.Binding/jars"
rm -Rf $AARS_DIR && rm -Rf $JARS_DIR
mkdir -p $AARS_DIR && mkdir -p $JARS_DIR

echo "Copy library aar .."
cp binding/build/outputs/aar/binding-release.aar $AARS_DIR

echo " ===================== Jars diff ====================="
# androidx is added via nuget
#diff -rq binding/xamarin ../Android.Binding/jars | grep -vE 'org.jetbrains|com.google|: androidx|binding-release.aar'
# Find all .aar and .jar files, excluding specific patterns
echo "Moving aars and jars excluding pattern 'org.jetbrains|com.google|androidx|binding-release.aar'"
find binding/xamarin -type f \( -name "*.aar" -o -name "*.jar" \) | \
    grep -vE 'org.jetbrains|com.google|androidx|binding-release.aar' | \
    while read -r file; do
        # Check if it's flutter_embedding jar
        if [[ $file == *"flutter_embedding"* ]]; then
            cp "$file" "$AARS_DIR"
            echo "Moved flutter_embedding JAR to AARS: $file"
        # Determine if it's an aar or jar file
        elif [[ $file == *.aar ]]; then
            cp "$file" "$AARS_DIR"
            echo "Moved AAR: $file"
        elif [[ $file == *.jar ]]; then
            cp "$file" "$JARS_DIR"
            echo "Moved JAR: $file"
        fi
    done
    
echo "Extract architecture-specific jars"
# Process each architecture
for arch in "arm64_v8a" "armeabi_v7a" "x86_64"; do
    # Convert architecture name if needed
    if [[ $arch == "arm64_v8a" ]]; then
        dir_arch="arm64-v8a"
    elif [[ $arch == "armeabi_v7a" ]]; then
        dir_arch="armeabi-v7a"
    else
        dir_arch=$arch
    fi
    
    jar_file=$(find "$JARS_DIR" -name "io.flutter.${arch}_release-*.jar")
    if [ -f "$jar_file" ]; then
        output_dir="$JARS_DIR/$dir_arch"
        mkdir -p "$output_dir"
        
        echo "Processing: $(basename "$jar_file")"
        unzip -j "$jar_file" "lib/$dir_arch/libflutter.so" -d "$output_dir"
        
        if [ $? -eq 0 ]; then
            echo "Successfully extracted libflutter.so for $dir_arch"
            echo "Removing: $(basename "$jar_file")"
            rm "$jar_file"
        else
            echo "Failed to extract library for $dir_arch"
        fi
    else
        echo "Warning: Could not find JAR for architecture: $arch"
    fi
done

#echo "Copy the missing jars or install via nuget (if any)"
echo " ===================== Jars diff ====================="
rm -Rf build
rm -Rf binding/build
rm -Rf demoapp/build