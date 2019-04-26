using build

class Build : BuildPod {

    new make() {
        podName = "afFandoc"
        summary = "Alternative and extensible Fandoc writers that provide intelligent context."
        version = Version("0.0.2")

        meta = [
            "pod.dis"       : "Fandoc",
            "repo.internal" : "true",
            "repo.tags"     : "system",
            "repo.public"   : "true"
        ]

        depends = [
            "sys    1.0.69 - 1.0",
            "fandoc 1.0.69 - 1.0",
            "syntax 1.0.69 - 1.0",

        ]

        srcDirs = [`fan/`, `test/`]
        resDirs = [`doc/`]

        meta["afBuild.testPods"]    = ""
    }
}