using System.IO;
using UnityEditor;
using UnityEngine;

[CustomEditor(typeof(RayMarchCamera))]
public class RayMarchCameraEditor : Editor
{
    RayMarchCamera targ { get { return target as RayMarchCamera; } }

    override public void OnInspectorGUI()
    {
        base.OnInspectorGUI();

        if (GUILayout.Button("Build Shader")) {
            buildShader(buildDistanceFunction());
        }
    }

    void buildShader(string distanceFunction)
    {
        var template = File.ReadAllText(Application.dataPath + "/SceneShaderTemplate.shader");
        var lines = template.Split('\n');
        for (int i = 0; i < lines.Length; ++i) {
            if (lines[i].Contains("__DISTANCE_FUNCTION")) {
                lines[i] = distanceFunction;
            }
            else if (lines[i].Contains("__SHADER_TITLE")) {
                lines[i] = "Shader \"Generated/SceneShader\" {";
            }
            else if (lines[i].Contains("__UNIFORMS")) {
                lines[i] = "uniform float4x4 _Cube;";
            }
        }
        var shaderCode = string.Join("\n", lines);

        File.WriteAllText(Application.dataPath + "/_GeneratedSceneShader.shader", shaderCode);
        AssetDatabase.Refresh();
    }

    string buildDistanceFunction()
    {
        var func = "";
        foreach (var obj in FindObjectsOfType<RayMarchObject>()) {
            func = obj.GetDistanceFunction(); // lol
        }
        return func;
    }
}