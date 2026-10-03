package com.gameshield.manager.data.model

/** 环境检测项：分区 | 键 | 值 | 级别(ok/warn/bad/info) */
data class EnvItem(
    val section: String,
    val key: String,
    val value: String,
    val level: String,
)

object EnvParser {
    fun parse(raw: List<String>): List<EnvItem> = raw.mapNotNull { line ->
        val p = line.split("|")
        if (p.size < 3) null
        else EnvItem(
            section = p[0].trim(),
            key = p[1].trim(),
            value = p[2].trim(),
            level = p.getOrElse(3) { "info" }.trim(),
        )
    }.filter { it.section.isNotEmpty() }

    /** 保持原始顺序分组 */
    fun group(items: List<EnvItem>): List<Pair<String, List<EnvItem>>> {
        val order = LinkedHashMap<String, MutableList<EnvItem>>()
        for (it in items) order.getOrPut(it.section) { mutableListOf() }.add(it)
        return order.map { it.key to it.value }
    }
}
