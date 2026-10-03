import { execFile } from "node:child_process";
import { readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import { promisify } from "node:util";
import { useEffect, useState } from "react";
import { Action, ActionPanel, closeMainWindow, Grid, Icon, showToast, Toast } from "@vicinae/api";

const run = promisify(execFile);
const THEME_SET = join(homedir(), "dotfiles/scripts/theme-set");
const STATE = join(homedir(), ".cache/theme/state.json");

type Variant = { args: string[]; group: string; title: string; preview: string };
type Theme = { id: string; name: string; preview: string; variants: Variant[] };

const pretty = (id: string) => id.split("-").map((w) => w[0].toUpperCase() + w.slice(1)).join(" ");

function flag(args: string[], name: string) {
  const i = args.indexOf(name);
  return i < 0 ? "" : args[i + 1];
}

// theme-set --menu prints 'args<TAB>label<TAB>preview' rows: the bare theme id
// first, then one row per flavor+accent or per variant
async function loadThemes(): Promise<Theme[]> {
  const { stdout } = await run(THEME_SET, ["--menu"], { maxBuffer: 1 << 22 });
  const themes = new Map<string, Theme>();

  for (const line of stdout.split("\n")) {
    const [argStr, label, preview] = line.split("\t");
    if (!argStr) continue;
    const args = argStr.split(" ");
    const id = args[0];

    if (args.length === 1) {
      themes.set(id, { id, name: label, preview, variants: [] });
      continue;
    }

    const flavor = flag(args, "--flavor");
    themes.get(id)?.variants.push({
      args,
      group: flavor ? pretty(flavor) : "",
      title: pretty(flavor ? flag(args, "--accent") : flag(args, "--variant")),
      preview,
    });
  }
  return [...themes.values()];
}

type State = { theme?: string; flavor?: string; accent?: string; variant?: string };

function readState(): State {
  try {
    return JSON.parse(readFileSync(STATE, "utf8"));
  } catch {
    return {};
  }
}

function readActive(): string {
  const s = readState();
  return [s.theme, s.flavor && `--flavor ${s.flavor}`, s.accent && `--accent ${s.accent}`, s.variant && `--variant ${s.variant}`]
    .filter(Boolean)
    .join(" ");
}

function activeLabel(themes: Theme[] | undefined): string {
  const s = readState();
  if (!s.theme) return "";
  const name = themes?.find((t) => t.id === s.theme)?.name ?? pretty(s.theme);
  return [name, ...[s.flavor, s.accent, s.variant].filter(Boolean).map((p) => pretty(p!))].join(" ");
}

function useActive() {
  const [active, setActive] = useState(readActive);

  async function apply(args: string[], label: string, close = false) {
    const toast = await showToast({ style: Toast.Style.Animated, title: `Applying ${label}` });
    try {
      await run(THEME_SET, args);
      setActive(readActive());
      toast.style = Toast.Style.Success;
      toast.title = `Theme: ${label}`;
      if (close) await closeMainWindow();
    } catch (e) {
      toast.style = Toast.Style.Failure;
      toast.title = "theme-set failed";
      toast.message = e instanceof Error ? e.message : String(e);
    }
  }

  return { active, apply };
}

function ApplyActions({ apply, args, label }: { apply: ReturnType<typeof useActive>["apply"]; args: string[]; label: string }) {
  return (
    <ActionPanel>
      <Action title="Apply" icon={Icon.Brush} onAction={() => apply(args, label)} />
      <Action title="Apply and Close" icon={Icon.Brush} onAction={() => apply(args, label, true)} />
    </ActionPanel>
  );
}

function VariantGrid({ theme }: { theme: Theme }) {
  const { active, apply } = useActive();
  const groups = [...new Set(theme.variants.map((v) => v.group))];

  return (
    <Grid columns={4} aspectRatio="4/3" fit={Grid.Fit.Contain} navigationTitle={theme.name} searchBarPlaceholder={`Search ${theme.name}...`}>
      {groups.map((group) => (
        <Grid.Section key={group} title={group || theme.name}>
          {theme.variants
            .filter((v) => v.group === group)
            .map((v) => (
              <Grid.Item
                key={v.args.join(" ")}
                content={v.preview}
                title={v.title}
                subtitle={active === v.args.join(" ") ? "Active" : undefined}
                keywords={[group]}
                actions={<ApplyActions apply={apply} args={v.args} label={`${theme.name} ${group} ${v.title}`.trim()} />}
              />
            ))}
        </Grid.Section>
      ))}
    </Grid>
  );
}

export default function PickTheme() {
  const [themes, setThemes] = useState<Theme[]>();
  const { active, apply } = useActive();

  useEffect(() => {
    loadThemes().then(setThemes, (e) =>
      showToast({ style: Toast.Style.Failure, title: "theme-set --menu failed", message: String(e) }),
    );
  }, []);

  return (
    <Grid
      columns={4}
      aspectRatio="4/3"
      fit={Grid.Fit.Contain}
      isLoading={!themes}
      navigationTitle={activeLabel(themes) ? `Pick Theme · Current: ${activeLabel(themes)}` : "Pick Theme"}
      searchBarPlaceholder="Search themes..."
    >
      {themes?.map((t) => {
        const isActive = active.split(" ")[0] === t.id;

        return (
          <Grid.Item
            key={t.id}
            content={t.preview}
            title={t.name}
            subtitle={isActive ? "Active" : t.variants.length ? `${t.variants.length} variants` : undefined}
            actions={
              t.variants.length ? (
                <ActionPanel>
                  <Action.Push title="Show Variants" icon={Icon.AppWindowGrid3x3} target={<VariantGrid theme={t} />} />
                </ActionPanel>
              ) : (
                <ApplyActions apply={apply} args={[t.id]} label={t.name} />
              )
            }
          />
        );
      })}
    </Grid>
  );
}
