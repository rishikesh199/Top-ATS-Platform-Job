// Top ATS Platform Jobs — Portfolio Interactions (Zero External Dependencies)
document.addEventListener("DOMContentLoaded", () => {
  // Generic tab switcher
  document.querySelectorAll("[data-tab-group]").forEach((group) => {
    const groupName = group.getAttribute("data-tab-group");
    const buttons = group.querySelectorAll(".tab-btn");
    const panels = document.querySelectorAll(`[data-tab-panel="${groupName}"]`);

    buttons.forEach((btn) => {
      btn.addEventListener("click", () => {
        const target = btn.getAttribute("data-target");
        buttons.forEach((b) => {
          b.classList.remove("active");
          b.setAttribute("aria-selected", "false");
        });
        panels.forEach((p) => p.classList.remove("active"));
        btn.classList.add("active");
        btn.setAttribute("aria-selected", "true");
        const activePanel = document.getElementById(target);
        if (activePanel) activePanel.classList.add("active");
      });
    });
  });

  // Screenshot gallery category filter (line-by-line rows)
  const filterButtons = document.querySelectorAll("[data-gallery-filter]");
  const shotRows = document.querySelectorAll(".shot-row");
  filterButtons.forEach((btn) => {
    btn.addEventListener("click", () => {
      const cat = btn.getAttribute("data-gallery-filter");
      filterButtons.forEach((b) => {
        b.classList.remove("active");
        b.setAttribute("aria-pressed", "false");
      });
      btn.classList.add("active");
      btn.setAttribute("aria-pressed", "true");

      shotRows.forEach((row) => {
        const rowCat = row.getAttribute("data-category");
        row.hidden = cat !== "all" && rowCat !== cat;
      });
    });
  });

  // Accessible Lightbox Modal (supports both .shot-row and .mini-shot)
  const modal = document.getElementById("lightbox-modal");
  const modalImg = document.getElementById("lightbox-img");
  const modalTitle = document.getElementById("lightbox-title");
  const modalCaption = document.getElementById("lightbox-caption");
  const modalEvidence = document.getElementById("lightbox-evidence");
  const closeBtn = document.getElementById("lightbox-close");
  let lastTrigger = null;

  function openLightbox(trigger, img, title, caption, evidence) {
    if (!modal || !img) return;
    lastTrigger = trigger;
    modalImg.src = img.src;
    modalImg.alt = img.alt;
    modalTitle.textContent = title;
    modalCaption.textContent = caption;
    if (modalEvidence) {
      modalEvidence.textContent = evidence || "";
      modalEvidence.style.display = evidence ? "block" : "none";
    }
    modal.classList.add("open");
    modal.setAttribute("aria-hidden", "false");
    closeBtn?.focus();
  }

  function closeModal() {
    if (!modal) return;
    modal.classList.remove("open");
    modal.setAttribute("aria-hidden", "true");
    if (lastTrigger) lastTrigger.focus();
  }

  document.querySelectorAll(".shot-thumb-btn").forEach((btn) => {
    btn.addEventListener("click", () => {
      const img = btn.querySelector("img");
      const row = btn.closest(".shot-row");
      const title = row?.querySelector(".shot-name")?.textContent || img?.alt || "";
      const caption = row?.querySelector(".shot-desc")?.textContent || "";
      const evidence = row?.querySelector(".shot-evidence")?.textContent || "";
      openLightbox(btn, img, title, caption, evidence);
    });
  });

  document.querySelectorAll(".mini-shot button").forEach((btn) => {
    btn.addEventListener("click", () => {
      const img = btn.querySelector("img");
      const card = btn.closest(".mini-shot");
      const title = card?.querySelector("strong")?.textContent || img?.alt || "";
      const caption = card?.querySelector(".mini-shot-cap")?.textContent || "";
      openLightbox(btn, img, title, caption, "");
    });
  });

  closeBtn?.addEventListener("click", closeModal);
  modal?.addEventListener("click", (e) => {
    if (e.target === modal) closeModal();
  });
  document.addEventListener("keydown", (e) => {
    if (e.key === "Escape" && modal?.classList.contains("open")) {
      closeModal();
    }
  });
});
