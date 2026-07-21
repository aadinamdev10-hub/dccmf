package apps.dccmf.util;

import java.util.List;
import java.util.Map;

/**
 * Record holding the results of a paginated search query.
 */
public record SearchResult(
    List<Map<String, Object>> data,
    long totalCount,
    int page,
    int pageSize
) {}
