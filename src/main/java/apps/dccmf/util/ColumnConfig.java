package apps.dccmf.util;

/**
 * Configuration mapping for a single column.
 * Converted to standard POJO class for universal Gson compatibility (fixes "Cannot set final field" on older Gson versions).
 */
public class ColumnConfig {
    private String name;
    private boolean editable;
    private boolean searchKey;
    private String uiType;
    private String apiSource;
    private boolean required;
    private String validation; // None, Email, Numeric, Date, Regex, Range
    private String regex;
    private Boolean visible = true;
    private Double min;
    private Double max;
    private Integer maxSizeMb;
    private String allowedExtensions;

    // No-arg constructor for Gson
    public ColumnConfig() {
    }

    public ColumnConfig(String name, boolean editable, boolean searchKey, String uiType, String apiSource,
                        boolean required, String validation, String regex, Boolean visible,
                        Double min, Double max, Integer maxSizeMb, String allowedExtensions) {
        this.name = name;
        this.editable = editable;
        this.searchKey = searchKey;
        this.uiType = uiType;
        this.apiSource = apiSource;
        this.required = required;
        this.validation = validation;
        this.regex = regex;
        this.visible = visible != null ? visible : true;
        this.min = min;
        this.max = max;
        this.maxSizeMb = maxSizeMb;
        this.allowedExtensions = allowedExtensions;
    }

    // Accessors matching record style for backward compatibility
    public String name() { return name; }
    public boolean editable() { return editable; }
    public boolean searchKey() { return searchKey; }
    public String uiType() { return uiType; }
    public String apiSource() { return apiSource; }
    public boolean required() { return required; }
    public String validation() { return validation; }
    public String regex() { return regex; }
    public Boolean visible() { return visible != null ? visible : true; }
    public Double min() { return min; }
    public Double max() { return max; }
    public Integer maxSizeMb() { return maxSizeMb; }
    public String allowedExtensions() { return allowedExtensions; }

    public boolean isVisible() {
        return visible == null || visible;
    }

    // Setters (if needed)
    public void setName(String name) { this.name = name; }
    public void setEditable(boolean editable) { this.editable = editable; }
    public void setSearchKey(boolean searchKey) { this.searchKey = searchKey; }
    public void setUiType(String uiType) { this.uiType = uiType; }
    public void setApiSource(String apiSource) { this.apiSource = apiSource; }
    public void setRequired(boolean required) { this.required = required; }
    public void setValidation(String validation) { this.validation = validation; }
    public void setRegex(String regex) { this.regex = regex; }
    public void setVisible(Boolean visible) { this.visible = visible; }
    public void setMin(Double min) { this.min = min; }
    public void setMax(Double max) { this.max = max; }
    public void setMaxSizeMb(Integer maxSizeMb) { this.maxSizeMb = maxSizeMb; }
    public void setAllowedExtensions(String allowedExtensions) { this.allowedExtensions = allowedExtensions; }
}
