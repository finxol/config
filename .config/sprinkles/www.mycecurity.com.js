console.log("Optimized Mycecurity sprinkle is running.");
("this is pretty cool");

/**
 * Finds and formats ISO date strings within a given DOM node and its children.
 * @param {Node} node The root node to search within.
 */
function formatDatesWithinNode(node) {
    // 1. Ensure the node is an element we can query.
    //    This filters out text nodes, comments, etc.
    if (!(node instanceof Element)) {
        return;
    }

    // 2. Create a list of candidates to check:
    //    - The node itself (if it's a potential candidate).
    //    - All descendant elements that could contain a date.
    const candidates = [node, ...node.querySelectorAll("div, span, p, td")];

    // 3. Filter the candidates to find only the ones with parsable dates.
    const dateElements = candidates.filter(
        (el) => el.textContent && !isNaN(Date.parse(el.textContent.trim())),
    );

    // 4. Loop through and format the valid date elements.
    for (const element of dateElements) {
        // Skip elements we have already formatted to prevent errors.
        if (element.dataset.formatted) continue;

        const originalDate = element.textContent.trim();
        element.textContent = new Date(originalDate).toLocaleDateString(
            "fr-FR",
            {
                year: "numeric",
                month: "numeric",
                day: "numeric",
            },
        );

        // Mark the element as formatted.
        element.dataset.formatted = "true";
    }
}

// Create an observer that will run our function on specific added nodes.
const observer = new MutationObserver((mutationsList) => {
    for (const mutation of mutationsList) {
        // We only care about 'childList' mutations (nodes being added/removed).
        if (mutation.type === "childList") {
            // For every node that was added, run our formatting function on it.
            for (const addedNode of mutation.addedNodes) {
                formatDatesWithinNode(addedNode);
            }
        }
    }
});

// Start observing the entire body for changes to its descendants.
observer.observe(document.body, {
    childList: true,
    subtree: true,
});

// Finally, run the function once on the entire body for the initial page load.
formatDatesWithinNode(document.body);
