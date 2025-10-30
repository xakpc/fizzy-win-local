const EDGE_THRESHOLD = 16

export function orient(el, orient = true) {
  const directions = [
    ["orient-left", spaceOnRight],
    ["orient-right", spaceOnLeft],
    ["orient-top", spaceOnBottom],
    ["orient-bottom", spaceOnTop]
  ];

  directions.forEach(([className, fn]) =>
    el.classList[orient && fn(el) < EDGE_THRESHOLD ? "add" : "remove"](className)
  );
}

function spaceOnLeft(el) {
  return el.getBoundingClientRect().left
}

function spaceOnRight(el) {
  return window.innerWidth - el.getBoundingClientRect().right
}

function spaceOnBottom(el) {
  return window.innerHeight - el.getBoundingClientRect().bottom
}

function spaceOnTop(el) {
  return el.getBoundingClientRect().top
}
