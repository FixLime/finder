plugins {
    id("com.android.application") version "8.2.2" apply false
    id("com.android.library") version "8.2.2" apply false
    id("org.jetbrains.kotlin.android") version "1.9.22" apply false
}

buildscript {
    extra.apply {
        set("composeBomVersion", "2024.02.00")
        set("kotlinVersion", "1.9.22")
        set("agpVersion", "8.2.2")
    }
}

tasks.register("clean", Delete::class) {
    delete(rootProject.layout.buildDirectory)
}
