using build::BuildPod

class Build : BuildPod {

    new make() {
        podName = "afFandoc"
        summary = "Intelligent and extensible Fandoc writers"
        version = Version("2.1.1")

        meta = [
            "pod.dis"       : "Fandoc",
            "repo.internal" : "true",
            "repo.tags"     : "system",
            "repo.public"   : "true"
        ]

        depends = [
            "sys    1.0.78 - 1.0",
            "fandoc 1.0.78 - 1.0",
            "syntax 1.0.78 - 1.0",
        ]

        srcDirs = [`fan/`, `fan/processors/`, `fan/resolvers/`, `test/`]
        resDirs = [`doc/`, `etc/syntax/`]

        meta["afBuild.testPods"]    = ""
    }
}