/// List of predefined positions for employees
/// This list can be easily updated in the future
class EmployeePositions {
  // IT/Technology Positions
  static const List<String> itPositions = [
    'Software Engineer',
    'Senior Software Engineer',
    'Lead Software Engineer',
    'Full Stack Developer',
    'Frontend Developer',
    'Backend Developer',
    'Mobile App Developer',
    'DevOps Engineer',
    'Cloud Engineer',
    'System Administrator',
    'Network Administrator',
    'Database Administrator',
    'Data Engineer',
    'Data Scientist',
    'Machine Learning Engineer',
    'AI Engineer',
    'QA Engineer',
    'Test Engineer',
    'Security Engineer',
    'Cybersecurity Analyst',
    'IT Support Specialist',
    'Technical Support Engineer',
    'IT Manager',
    'CTO (Chief Technology Officer)',
    'Product Manager',
    'Technical Product Manager',
    'Scrum Master',
    'Agile Coach',
    'UI/UX Designer',
    'UI Designer',
    'UX Designer',
    'Graphic Designer',
    'Technical Writer',
    'Solutions Architect',
    'Enterprise Architect',
    'Business Analyst',
    'Technical Business Analyst',
    'Project Manager',
    'IT Project Manager',
    'Software Architect',
    'Site Reliability Engineer (SRE)',
    'Platform Engineer',
    'Infrastructure Engineer',
    'Release Engineer',
    'Build Engineer',
    'Automation Engineer',
    'Performance Engineer',
    'Embedded Systems Engineer',
    'Firmware Engineer',
    'Game Developer',
    'Blockchain Developer',
  ];

  // General/Other Positions (can be expanded)
  static const List<String> generalPositions = [
    'Manager',
    'Senior Manager',
    'Director',
    'Senior Director',
    'VP (Vice President)',
    'CEO (Chief Executive Officer)',
    'CFO (Chief Financial Officer)',
    'COO (Chief Operating Officer)',
    'CMO (Chief Marketing Officer)',
    'CHRO (Chief Human Resources Officer)',
    'Administrator',
    'Coordinator',
    'Specialist',
    'Analyst',
    'Consultant',
    'Assistant',
    'Executive Assistant',
    'Intern',
    'Trainee',
  ];

  /// Get all available positions
  static List<String> get allPositions => [
        ...itPositions,
        ...generalPositions,
      ];

  /// Check if a position is in the predefined list
  static bool isPredefined(String position) {
    return allPositions.contains(position);
  }
}

