// AntiGem WebView MCP Service Worker for 2D Video Editing Studio
const PLUGIN_ID = "2d-video-editing-studio";
const PLUGIN_VERSION = "3.1.0";

const STYLES = {
  documentary: {
    name: "Vox Documentary Explainer",
    recipes: ["stat_hero", "polaroid_pin", "arch_orb", "seesaw_compare", "light_cone", "selective_mono"],
    palette: ["#F4ECE1", "#E63946", "#FFB703", "#1D3557", "#111111"]
  },
  stickman: {
    name: "Stickman / Modern Storytelling Hybrid",
    recipes: ["story_scene", "speech_sticker", "story_desk", "fork_in_road", "selective_color"],
    palette: ["#F8F6EF", "#FF6B35", "#1D3557", "#2B2D42", "#111111"]
  },
  sticker: {
    name: "Pop-Art Cutouts & Sticker Hybrid",
    recipes: ["hero", "duo", "trio", "speech_sticker", "badge_pop"],
    palette: ["#FFFFFF", "#E63946", "#FFB703", "#06D6A0", "#111111"]
  },
  noir: {
    name: "Suspense Noir / Crime Documentary",
    recipes: ["redact_bar", "cctv_timestamp", "evidence_board", "case_file"],
    palette: ["#0D0D0D", "#C1121F", "#FDF0D5", "#669BBC", "#222222"]
  },
  arcade: {
    name: "Retro 8-Bit Arcade",
    recipes: ["rpg_dialogue", "hp_bar", "coin_counter", "pixel_stage"],
    palette: ["#1A1A2E", "#E94560", "#F8B500", "#00B4D8", "#0F3460"]
  },
  doodle: {
    name: "Hand-Drawn Doodle & Sketchbook",
    recipes: ["doodle_circle", "notebook_sketch", "marker_underline", "sticky_note"],
    palette: ["#FAF7EE", "#2B2D42", "#E63946", "#457B9D", "#333333"]
  }
};

self.addEventListener("install", (event) => {
  console.log(`[${PLUGIN_ID}] Service Worker installed (v${PLUGIN_VERSION})`);
  self.skipWaiting();
});

self.addEventListener("activate", (event) => {
  console.log(`[${PLUGIN_ID}] Service Worker activated`);
  if (self.clients && self.clients.claim) {
    event.waitUntil(self.clients.claim());
  }
});

// MCP Tool Call Listener for AntiGem Runtime
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.type !== "mcp_tool_call") return false;

  (async () => {
    const tool = message.tool;
    const args = message.args || {};

    if (tool === "studio_status") {
      return {
        id: PLUGIN_ID,
        name: "2D Video Editing Studio",
        version: PLUGIN_VERSION,
        status: "ready",
        supported_styles: Object.keys(STYLES),
        features: {
          audio_mix: "Cartesia TTS + automatic music ducking & SFX hits (-14 LUFS)",
          asset_generation: "Google Flow parallel rapid dispatch ($0 API cost)",
          rendering: "Mobile/Desktop multi-core OpenCV + PIL pipeline with 2-tier soft shadows",
          variety_engine: "Creative Director motif limits (max 2 rubber stamps per video)"
        }
      };
    }

    if (tool === "studio_list_styles") {
      if (args.style && STYLES[args.style]) {
        return { style: args.style, details: STYLES[args.style] };
      }
      return { styles: STYLES };
    }

    if (tool === "studio_plan_project") {
      const topic = args.topic || "Untitled Video";
      const style = args.style || "documentary";
      const aspect = args.aspect || "9:16";
      const lines = args.lines || ["Hook: The untold secret.", "Development: How the system works.", "Climax: The truth revealed."];

      const beats = lines.map((text, idx) => ({
        index: idx + 1,
        line: text,
        suggested_recipe: (STYLES[style] && STYLES[style].recipes[idx % STYLES[style].recipes.length]) || "hero",
        layout: idx % 2 === 0 ? "hero" : "duo"
      }));

      return {
        project: topic.toLowerCase().replace(/[^a-z0-9]+/g, "_"),
        style,
        aspect,
        line_count: lines.length,
        visual_beats: beats,
        next_step: "Run python studio.py voice followed by python studio.py plan on device."
      };
    }

    if (tool === "studio_render_command") {
      const projectDir = args.project_dir || "projects/my_video";
      const isPreview = Boolean(args.preview_only);

      return {
        project_dir: projectDir,
        preview_command: `python studio.py preview --project "${projectDir}"`,
        master_command: `python studio.py render --project "${projectDir}"`,
        recommended: isPreview
          ? `python studio.py preview --project "${projectDir}"`
          : `python studio.py render --project "${projectDir}"`
      };
    }

    throw new Error(`Unknown MCP tool: ${tool}`);
  })()
    .then(result => sendResponse({
      isError: false,
      content: [{ type: "text", text: typeof result === "string" ? result : JSON.stringify(result, null, 2) }]
    }))
    .catch(error => sendResponse({
      isError: true,
      content: [{ type: "text", text: error.message }]
    }));

  return true;
});
