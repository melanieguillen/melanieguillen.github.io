const sidebar = document.querySelector("[data-sidebar]");
const menuButton = document.querySelector("[data-menu-button]");
const navLinks = [...document.querySelectorAll("[data-view-link]")];
const siteViews = [...document.querySelectorAll("[data-site-view]")];

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
  updates: "home",
  contact: "home",
  publications: "publications",
  patents: "publications",
  projects: "projects",
  research: "projects",
};

function showView(route, scrollToTop = false) {
  const viewId = routeToView[route] || "home";

  siteViews.forEach((view) => {
    const isActive = view.dataset.siteView === viewId;
    view.hidden = !isActive;
    view.classList.toggle("is-active", isActive);
  });

  setActiveLink(viewId);

  if (scrollToTop || route === viewId) {
    window.scrollTo({ top: 0, behavior: scrollToTop ? "smooth" : "auto" });
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

const carousel = document.querySelector("[data-carousel]");

if (carousel) {
  const slides = [...carousel.querySelectorAll("[data-carousel-slide]")];
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
    dot.setAttribute("aria-label", `Show illustration ${index + 1}`);
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

const yearNode = document.getElementById("year");
if (yearNode) {
  yearNode.textContent = new Date().getFullYear();
}

window.addEventListener("resize", () => {
  if (window.innerWidth > 1100) {
    closeMenu();
  }
});
