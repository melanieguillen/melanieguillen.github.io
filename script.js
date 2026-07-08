const sidebar = document.querySelector("[data-sidebar]");
const menuButton = document.querySelector("[data-menu-button]");
const navLinks = [...document.querySelectorAll("[data-view-link]")];
const siteViews = [...document.querySelectorAll("[data-site-view]")];
const pageContent = document.querySelector(".page");

const closeMenu = () => {
  if (!sidebar) {
    return;
  }

  sidebar.classList.remove("is-open");
  document.body.classList.remove("menu-open");
};

if (menuButton && sidebar) {
  menuButton.addEventListener("click", () => {
    const isOpen = sidebar.classList.toggle("is-open");
    document.body.classList.toggle("menu-open", isOpen);
  });
}

navLinks.forEach((link) => {
  link.addEventListener("click", (event) => {
    event.preventDefault();
    const viewId = link.dataset.viewLink;
    history.pushState(null, "", `#${viewId}`);
    showView(viewId, true);
    closeMenu();
  });
});

const setActiveLink = (viewId) => {
  navLinks.forEach((link) => {
    const isActive = link.dataset.viewLink === viewId;
    link.classList.toggle("is-active", isActive);
    if (isActive) {
      link.setAttribute("aria-current", "page");
    } else {
      link.removeAttribute("aria-current");
    }
  });
};

const routeToView = {
  home: "home",
  about: "home",
  "track-record": "home",
  "cover-artwork": "home",
  updates: "home",
  contact: "home",
  news: "news",
  "latest-updates": "news",
  "social-feed": "news",
  publications: "publications",
  patents: "publications",
  projects: "projects",
  research: "projects",
};

function scrollToPageContent(behavior = "auto") {
  if (pageContent) {
    pageContent.scrollIntoView({ behavior, block: "start" });
    return;
  }

  window.scrollTo({ top: 0, behavior });
}

function showView(route, scrollToContent = false) {
  const viewId = routeToView[route] || "home";

  siteViews.forEach((view) => {
    const isActive = view.dataset.siteView === viewId;
    view.hidden = !isActive;
    view.classList.toggle("is-active", isActive);
  });

  setActiveLink(viewId);

  requestAnimationFrame(() => setupLinkedInPostBodies());

  if (scrollToContent) {
    requestAnimationFrame(() => scrollToPageContent("smooth"));
    return;
  }

  if (route === viewId) {
    window.scrollTo({ top: 0, behavior: "auto" });
    return;
  }

  const target = document.getElementById(route);
  if (target) {
    requestAnimationFrame(() => target.scrollIntoView());
  }
}

const applyRoute = () => {
  const route = window.location.hash.slice(1) || "home";
  showView(route);
  closeMenu();
};

window.addEventListener("hashchange", applyRoute);
window.addEventListener("popstate", applyRoute);
applyRoute();

function setupLinkedInPostBodies() {
  const bodies = [...document.querySelectorAll(".linkedin-post__body")];

  bodies.forEach((body, index) => {
    const existingButton = body.nextElementSibling?.classList.contains("linkedin-post__more")
      ? body.nextElementSibling
      : null;

    if (body.dataset.expanded === "true") {
      body.classList.remove("is-collapsed");
      if (existingButton) {
        existingButton.remove();
      }
      return;
    }

    body.classList.remove("is-collapsed");
    if (existingButton) {
      existingButton.remove();
    }

    const styles = window.getComputedStyle(body);
    const fontSize = Number.parseFloat(styles.fontSize) || 15;
    const lineHeight = Number.parseFloat(styles.lineHeight) || fontSize * 1.52;
    const maxHeight = lineHeight * 4;

    if (body.scrollHeight <= maxHeight + 2) {
      return;
    }

    body.classList.add("is-collapsed");

    const moreButton = document.createElement("button");
    moreButton.type = "button";
    moreButton.className = "linkedin-post__more";
    moreButton.textContent = "more";
    moreButton.setAttribute("aria-expanded", "false");
    moreButton.setAttribute("aria-controls", `linkedin-post-body-${index + 1}`);

    if (!body.id) {
      body.id = `linkedin-post-body-${index + 1}`;
    }

    moreButton.addEventListener("click", () => {
      body.dataset.expanded = "true";
      body.classList.remove("is-collapsed");
      moreButton.remove();
    });

    body.insertAdjacentElement("afterend", moreButton);
  });
}

setupLinkedInPostBodies();

const carousel = document.querySelector("[data-carousel]");

if (carousel) {
  const slides = [...carousel.querySelectorAll("[data-carousel-slide]")];
  const track = carousel.querySelector("[data-carousel-track]");
  const previousButton = carousel.querySelector("[data-carousel-previous]");
  const nextButton = carousel.querySelector("[data-carousel-next]");
  const toggleButton = carousel.querySelector("[data-carousel-toggle]");
  const dotsContainer = carousel.querySelector("[data-carousel-dots]");
  const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  let currentSlide = 0;
  let isPaused = reducedMotion;
  let autoAdvance;

  const dots = slides.map((_, index) => {
    const dot = document.createElement("button");
    dot.type = "button";
    dot.setAttribute("aria-label", `Show artwork ${index + 1}`);
    dot.addEventListener("click", () => {
      showSlide(index);
      restartAutoAdvance();
    });
    dotsContainer.appendChild(dot);
    return dot;
  });

  const showSlide = (index) => {
    currentSlide = (index + slides.length) % slides.length;
    slides.forEach((slide, slideIndex) => {
      const isActive = slideIndex === currentSlide;
      slide.classList.toggle("is-active", isActive);
      slide.setAttribute("aria-hidden", String(!isActive));
    });
    if (track) {
      track.style.transform = `translateX(-${currentSlide * 100}%)`;
    }
    dots.forEach((dot, dotIndex) => {
      dot.classList.toggle("is-active", dotIndex === currentSlide);
    });
  };

  const stopAutoAdvance = () => {
    window.clearInterval(autoAdvance);
  };

  const startAutoAdvance = () => {
    stopAutoAdvance();
    if (!isPaused && slides.length > 1) {
      autoAdvance = window.setInterval(() => showSlide(currentSlide + 1), 5000);
    }
  };

  const restartAutoAdvance = () => {
    if (!isPaused) {
      startAutoAdvance();
    }
  };

  previousButton.addEventListener("click", () => {
    showSlide(currentSlide - 1);
    restartAutoAdvance();
  });

  nextButton.addEventListener("click", () => {
    showSlide(currentSlide + 1);
    restartAutoAdvance();
  });

  toggleButton.addEventListener("click", () => {
    isPaused = !isPaused;
    toggleButton.textContent = isPaused ? "Play" : "Pause";
    toggleButton.setAttribute(
      "aria-label",
      isPaused ? "Play automatic slideshow" : "Pause automatic slideshow"
    );
    startAutoAdvance();
  });

  carousel.addEventListener("mouseenter", stopAutoAdvance);
  carousel.addEventListener("mouseleave", startAutoAdvance);
  carousel.addEventListener("focusin", stopAutoAdvance);
  carousel.addEventListener("focusout", startAutoAdvance);

  document.addEventListener("visibilitychange", () => {
    if (document.hidden) {
      stopAutoAdvance();
    } else {
      startAutoAdvance();
    }
  });

  if (reducedMotion) {
    toggleButton.textContent = "Play";
    toggleButton.setAttribute("aria-label", "Play automatic slideshow");
  }

  showSlide(0);
  startAutoAdvance();
}

const videoTrigger = document.querySelector("[data-video-trigger]");

if (videoTrigger) {
  videoTrigger.addEventListener("click", () => {
    const videoId = videoTrigger.dataset.videoId;
    const videoFrame = videoTrigger.closest(".featured-video__frame");

    if (!videoId || !videoFrame) {
      return;
    }

    const iframe = document.createElement("iframe");
    iframe.src = `https://www.youtube-nocookie.com/embed/${encodeURIComponent(videoId)}?autoplay=1&rel=0`;
    iframe.title = "Pushing the Boundaries of Digital Chemistry";
    iframe.allow =
      "accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share";
    iframe.referrerPolicy = "strict-origin-when-cross-origin";
    iframe.allowFullscreen = true;

    videoFrame.replaceChildren(iframe);
  });
}

const yearNode = document.getElementById("year");
if (yearNode) {
  yearNode.textContent = new Date().getFullYear();
}

window.addEventListener("resize", () => {
  if (window.innerWidth > 1100) {
    closeMenu();
  }

  setupLinkedInPostBodies();
});
