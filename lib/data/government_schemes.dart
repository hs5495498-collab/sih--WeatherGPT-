import '../models/scheme.dart';

/// Static reference data on major Government of India agricultural schemes.
/// This is NOT fetched from any live API -- it's hand-maintained, general
/// public information from official scheme websites, meant as a quick
/// starting point and links-out, not a substitute for the official portal.
/// Benefit amounts and eligibility rules can change; each scheme links to
/// its real official .gov.in page, and the schemes screen shows a visible
/// "verify on the official site" notice rather than presenting this list
/// as guaranteed current.
const List<GovernmentScheme> kGovernmentSchemes = [
  GovernmentScheme(
    id: 'pm-kisan',
    name: 'PM-KISAN (Pradhan Mantri Kisan Samman Nidhi)',
    category: 'Income Support',
    benefit: '₹6,000/year paid in 3 installments of ₹2,000 directly to bank account',
    eligibility: 'Small and marginal landholding farmer families (subject to exclusion criteria for higher-income categories)',
    documents: ['Aadhaar card', 'Land ownership records', 'Bank account (Aadhaar-linked)'],
    applyUrl: 'https://pmkisan.gov.in/',
  ),
  GovernmentScheme(
    id: 'kcc',
    name: 'Kisan Credit Card (KCC)',
    category: 'Loans',
    benefit: 'Short-term crop loans at subsidized interest (as low as ~4% p.a. with prompt repayment incentive)',
    eligibility: 'Farmers, tenant farmers, sharecroppers, and self-help group members',
    documents: ['Identity proof', 'Address proof', 'Land documents', 'Passport-size photo'],
    applyUrl: 'https://www.myscheme.gov.in/schemes/kcc',
  ),
  GovernmentScheme(
    id: 'pmfby',
    name: 'Pradhan Mantri Fasal Bima Yojana (PMFBY)',
    category: 'Insurance',
    benefit: 'Crop insurance against yield loss from natural calamities, pests, and disease',
    eligibility: 'All farmers growing notified crops in notified areas (loanee and non-loanee both)',
    documents: ['Aadhaar card', 'Land records', 'Bank account details', 'Sowing declaration'],
    applyUrl: 'https://pmfby.gov.in/',
  ),
  GovernmentScheme(
    id: 'soil-health-card',
    name: 'Soil Health Card Scheme',
    category: 'Advisory',
    benefit: 'Free soil testing with crop-wise nutrient and fertilizer recommendations every 2 years',
    eligibility: 'All farmers',
    documents: ['Land details', 'Aadhaar card (for registration at local center)'],
    applyUrl: 'https://soilhealth.dac.gov.in/',
  ),
  GovernmentScheme(
    id: 'kusum',
    name: 'PM-KUSUM (Solar Pumps & Grid-Connected Solar)',
    category: 'Infrastructure',
    benefit: 'Subsidy (typically ~60%) on solar-powered irrigation pumps and grid-connected solar plants on farmland',
    eligibility: 'Individual farmers, farmer groups, cooperatives, panchayats',
    documents: ['Land documents', 'Electricity connection details (if applicable)', 'Bank account'],
    applyUrl: 'https://pmkusum.mnre.gov.in/',
  ),
  GovernmentScheme(
    id: 'pmksy',
    name: 'Pradhan Mantri Krishi Sinchayee Yojana (PMKSY)',
    category: 'Infrastructure',
    benefit: 'Support for irrigation infrastructure, micro-irrigation (drip/sprinkler), and "per drop more crop" efficiency',
    eligibility: 'Farmers, farmer groups, and state-implemented irrigation projects',
    documents: ['Land records', 'Water source details', 'Bank account'],
    applyUrl: 'https://pmksy.gov.in/',
  ),
  GovernmentScheme(
    id: 'enam',
    name: 'e-NAM (National Agriculture Market)',
    category: 'Market Access',
    benefit: 'Online trading platform connecting existing mandis for better price discovery and transparent auctions',
    eligibility: 'Farmers, traders, and buyers registered with a participating mandi',
    documents: ['Aadhaar card', 'Bank account', 'Mandi registration'],
    applyUrl: 'https://www.enam.gov.in/',
  ),
  GovernmentScheme(
    id: 'aif',
    name: 'Agriculture Infrastructure Fund (AIF)',
    category: 'Loans',
    benefit: 'Medium/long-term debt financing with interest subvention for post-harvest and farm-gate infrastructure',
    eligibility: 'Farmers, FPOs, cooperatives, agri-entrepreneurs, and state agencies',
    documents: ['Project proposal', 'Land/lease documents', 'Bank account', 'Identity proof'],
    applyUrl: 'https://agriinfra.dac.gov.in/',
  ),
  GovernmentScheme(
    id: 'smam',
    name: 'Sub-Mission on Agricultural Mechanization (SMAM)',
    category: 'Equipment',
    benefit: 'Subsidy on purchase of tractors, power tillers, and other farm machinery; support for Custom Hiring Centres',
    eligibility: 'Individual farmers (with priority for SC/ST/women/small farmers) and Custom Hiring Centre operators',
    documents: ['Land records', 'Bank account', 'Aadhaar card', 'Category certificate (if applicable)'],
    applyUrl: 'https://agrimachinery.nic.in/',
  ),
  GovernmentScheme(
    id: 'nfsm',
    name: 'National Food Security Mission (NFSM)',
    category: 'Advisory',
    benefit: 'Support for quality seeds, farm implements, and cropping-system demonstrations to raise foodgrain productivity',
    eligibility: 'Farmers in identified NFSM districts growing rice, wheat, pulses, coarse cereals, or nutri-cereals',
    documents: ['Land records', 'Bank account', 'Aadhaar card'],
    applyUrl: 'https://www.nfsm.gov.in/',
  ),
];
