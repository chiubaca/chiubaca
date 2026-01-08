#!/bin/bash

# Install curl and jq if not present
sudo apt-get update && sudo apt-get install -y curl jq

# Fetch RSS feed
RSS_CONTENT=$(curl -s "https://chiubaca.com/rss.xml")

# Parse RSS and extract latest posts
echo "$RSS_CONTENT" | xmllint --xpath "//item[position()<=5]" - 2>/dev/null > /tmp/items.xml || {
  echo "Failed to parse RSS. Installing xmlstarlet..."
  sudo apt-get install -y xmlstarlet
  echo "$RSS_CONTENT" | xmlstarlet sel -t -m "//item[position()<=5]" -c "." -n > /tmp/items.xml
}

# Create new content with the desired format
cat > README.md << 'EOF'
<div align="center">

# Hey, I'm Alex! 👋

</div>

<div align="center">

I'm software developer based in London 🇬🇧.

Always tinkering, learning and making ideas come to life 💫

</div>

---

<div align="center">

EOF

# Parse items and add to markdown (using xmlstarlet for reliability)
if command -v xmlstarlet >/dev/null 2>&1; then
  while IFS= read -r item; do
    title=$(echo "$item" | xmlstarlet sel -t -v "//title" - 2>/dev/null | head -1)
    link=$(echo "$item" | xmlstarlet sel -t -v "//link" - 2>/dev/null | head -1)
    pubDate=$(echo "$item" | xmlstarlet sel -t -v "//pubDate" - 2>/dev/null | head -1)
    
    if [[ -n "$title" && -n "$link" ]]; then
      # Format date nicely
      if [[ -n "$pubDate" ]]; then
        date_str=$(date -d "$pubDate" "+%b %d, %Y" 2>/dev/null || echo "$pubDate")
      else
        date_str=""
      fi
      
      if [[ -n "$date_str" ]]; then
        echo "$date_str |" >> README.md
        echo "[$title]($link)</strong>" >> README.md
        echo "" >> README.md
      fi
    fi
  done < <(echo "$RSS_CONTENT" | xmlstarlet sel -t -m "//item[position()<=5]" -c "." -n)
else
  # Fallback: simple text parsing
  echo "- RSS parsing failed. Please check the feed format." >> README.md
fi

echo "</div>" >> README.md
echo "" >> README.md
echo "<div align=\"center\">" >> README.md
echo "" >> README.md
echo "## Connect with me 🤙🏼" >> README.md
echo "" >> README.md
echo "</div>" >> README.md
echo "<p align=\"center\"><a href=\"https://bsky.app/profile/chiubaca.com\">Bluesky</a> | <a href=\"https://twitter.com/chiubaca\">Twitter</a> | <a href=\"https://mas.to/@chiubaca\">Mastodon</a></p>" >> README.md
echo "" >> README.md
echo "<p align=\"center\"><em>Last updated: $(date)</em></p>" >> README.md