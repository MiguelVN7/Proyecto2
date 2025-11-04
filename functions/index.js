// Firebase Cloud Functions Entry Point
// This file exports all functions for deployment

const classifyWasteFunctions = require('./classifyWaste');

// Export all functions
exports.classifyWaste = classifyWasteFunctions.classifyWaste;
exports.classifyWasteManual = classifyWasteFunctions.classifyWasteManual;
