import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:socialize/models/activity_category.dart';
import 'package:socialize/models/activity_model.dart';
import 'package:socialize/models/user_model.dart';
import 'package:socialize/providers/app_data_provider.dart';
import 'package:socialize/screens/activity/select_location_screen.dart';
import 'package:socialize/utils/helpers.dart';
import 'package:uuid/uuid.dart';

class CreateEditActivityScreen extends StatefulWidget {
  final ActivityModel? activityToEdit;

  const CreateEditActivityScreen({super.key, this.activityToEdit});

  bool get isEditing => activityToEdit != null;

  @override
  State<CreateEditActivityScreen> createState() =>
      _CreateEditActivityScreenState();
}

class _CreateEditActivityScreenState extends State<CreateEditActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  late TextEditingController _nameController;
  late TextEditingController _locationDetailsController;
  late TextEditingController _descriptionController;
  late TextEditingController _maxUsersController;

  ActivityCategory _selectedCategory = ActivityCategory.socialGathering;
  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate; // For display, actual end DateTime is combined
  TimeOfDay? _endTime;
  LatLng? _selectedLocation;

  List<UserModel> _joinedUsers = [];
  String? _selectedUserToPassCoordinator;


  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _locationDetailsController = TextEditingController();
    _descriptionController = TextEditingController();
    _maxUsersController = TextEditingController();

    if (widget.isEditing && widget.activityToEdit != null) {
      final activity = widget.activityToEdit!;
      _nameController.text = activity.name;
      _selectedCategory = activity.category;
      _locationDetailsController.text = activity.locationDetails;
      _descriptionController.text = activity.description;
      _startDate = activity.startTime;
      _startTime = TimeOfDay.fromDateTime(activity.startTime);
      _endDate = activity.endTime; // Date part of end time
      _endTime = TimeOfDay.fromDateTime(activity.endTime);
      _selectedLocation = activity.location;
      _maxUsersController.text = activity.maxUsers.toString();

      final appDataProvider = Provider.of<AppDataProvider>(context, listen: false);
      _joinedUsers = appDataProvider.getJoinedUsersForActivity(activity.id);
    } else {
       // Set default start time to tomorrow 9 AM
      _startDate = DateTime.now().add(const Duration(days: 1));
      _startTime = const TimeOfDay(hour: 9, minute: 0);
      // Set default end time to 2 hours after start
      DateTime combinedStart = DateTime(_startDate!.year, _startDate!.month, _startDate!.day, _startTime!.hour, _startTime!.minute);
      DateTime combinedEnd = combinedStart.add(const Duration(hours: 2));
      _endDate = combinedEnd;
      _endTime = TimeOfDay.fromDateTime(combinedEnd);

      _maxUsersController.text = "10"; // Default max users
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationDetailsController.dispose();
    _descriptionController.dispose();
    _maxUsersController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, bool isStartDate) async {
    final now = DateTime.now();
    final initialDate = (isStartDate ? _startDate : _endDate) ?? now.add(const Duration(days: 1));
    final firstDate = now; // Cannot select past date
    final lastDate = now.add(const Duration(days: 365 * 2)); // Up to 2 years in future

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(firstDate) ? firstDate : initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (pickedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = pickedDate;
          // If end date is before new start date, adjust end date
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = _startDate;
            // Also adjust end time if it makes the duration negative with current _endTime
             if (_startTime != null && _endTime != null) {
              DateTime combinedStart = DateTime(_startDate!.year, _startDate!.month, _startDate!.day, _startTime!.hour, _startTime!.minute);
              DateTime combinedEnd = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, _endTime!.hour, _endTime!.minute);
              if(combinedEnd.isBefore(combinedStart)) {
                _endTime = TimeOfDay(hour: _startTime!.hour + 2, minute: _startTime!.minute); // Default 2 hours later
                 // Handle overflow if hour > 23
                if (_endTime!.hour >= 24) {
                   _endTime = TimeOfDay(hour: 23, minute: 59);
                }
              }
            }
          }
        } else {
          _endDate = pickedDate;
        }
      });
    }
  }

  Future<void> _pickTime(BuildContext context, bool isStartTime) async {
    final initialTime = (isStartTime ? _startTime : _endTime) ?? TimeOfDay.now();
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (pickedTime != null) {
      setState(() {
        if (isStartTime) {
          _startTime = pickedTime;
        } else {
          _endTime = pickedTime;
        }
      });
    }
  }

  void _selectLocationOnMap() async {
    final LatLng? result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SelectLocationScreen(initialLocation: _selectedLocation),
      ),
    );
    if (result != null) {
      setState(() {
        _selectedLocation = result;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_startDate == null || _startTime == null || _endDate == null || _endTime == null) {
        showAppSnackBar(context, 'Please select start and end date/time.', isError: true);
        return;
      }
      if (_selectedLocation == null) {
        showAppSnackBar(context, 'Please select a location on the map.', isError: true);
        return;
      }

      final DateTime combinedStartDateTime = DateTime(
          _startDate!.year, _startDate!.month, _startDate!.day, _startTime!.hour, _startTime!.minute);
      final DateTime combinedEndDateTime = DateTime(
          _endDate!.year, _endDate!.month, _endDate!.day, _endTime!.hour, _endTime!.minute);

      if (combinedEndDateTime.isBefore(combinedStartDateTime)) {
        showAppSnackBar(context, 'End time cannot be before start time.', isError: true);
        return;
      }
       if (combinedStartDateTime.isBefore(DateTime.now().subtract(const Duration(minutes: 1)))) { // Allow a minute for processing
        showAppSnackBar(context, 'Start time cannot be in the past.', isError: true);
        return;
      }


      final appDataProvider = Provider.of<AppDataProvider>(context, listen: false);
      final currentUser = appDataProvider.currentUser;
      if (currentUser == null) return; // Should not happen

      final activity = ActivityModel(
        id: widget.isEditing ? widget.activityToEdit!.id : _uuid.v4(),
        name: _nameController.text.trim(),
        category: _selectedCategory,
        locationDetails: _locationDetailsController.text.trim(),
        description: _descriptionController.text.trim(),
        startTime: combinedStartDateTime,
        endTime: combinedEndDateTime,
        location: _selectedLocation!,
        maxUsers: int.tryParse(_maxUsersController.text) ?? 10,
        creatorId: widget.isEditing ? widget.activityToEdit!.creatorId : currentUser.id,
        coordinatorId: widget.isEditing ? widget.activityToEdit!.coordinatorId : currentUser.id,
        joinedUserIds: widget.isEditing ? widget.activityToEdit!.joinedUserIds : const [], // Keep existing users on edit
      );

      if (widget.isEditing) {
        appDataProvider.updateActivity(activity);
        showAppSnackBar(context, 'Activity updated successfully!');
      } else {
        appDataProvider.createActivity(activity);
        showAppSnackBar(context, 'Activity created successfully!');
      }
      Navigator.of(context).pop();
    }
  }

  void _handleDeleteUser(String userId) {
     if (!widget.isEditing || widget.activityToEdit == null) return;
    final appDataProvider = Provider.of<AppDataProvider>(context, listen: false);
    _showConfirmationDialog(context,
      title: "Remove User?",
      content: "Are you sure you want to remove this user from the activity?",
      onConfirm: () {
        appDataProvider.removeUserFromActivity(widget.activityToEdit!.id, userId);
        setState(() {
          _joinedUsers = appDataProvider.getJoinedUsersForActivity(widget.activityToEdit!.id);
           // If the user being passed coordinator role was removed, reset selection
          if (_selectedUserToPassCoordinator == userId) {
            _selectedUserToPassCoordinator = null;
          }
        });
        showAppSnackBar(context, "User removed.");
      }
    );
  }

  void _handlePassCoordinator() {
    if (!widget.isEditing || widget.activityToEdit == null || _selectedUserToPassCoordinator == null) {
      showAppSnackBar(context, "Please select a user to pass the coordinator role to.", isError: true);
      return;
    }
    final appDataProvider = Provider.of<AppDataProvider>(context, listen: false);
    _showConfirmationDialog(context,
      title: "Pass Coordinator Role?",
      content: "Are you sure you want to make this user the new coordinator? You will lose your coordinator privileges for this activity.",
      onConfirm: () {
        final success = appDataProvider.passCoordinatorRole(widget.activityToEdit!.id, _selectedUserToPassCoordinator!);
        if (success) {
          showAppSnackBar(context, "Coordinator role passed successfully.");
          Navigator.of(context).pop(); // Exit edit screen as user is no longer coordinator
        } else {
          showAppSnackBar(context, "Failed to pass coordinator role. Ensure the user is still part of the activity.", isError: true);
        }
      }
    );
  }

  void _handleDeleteActivity() {
    if (!widget.isEditing || widget.activityToEdit == null) return;
    final appDataProvider = Provider.of<AppDataProvider>(context, listen: false);
    final activity = widget.activityToEdit!;

    if (activity.joinedUserIds.isNotEmpty && activity.joinedUserIds.length > 0) { // Check if anyone (other than self if self is counted) joined
       // If self is the only one "joined" (as coordinator), allow delete.
       // This check implies other distinct users have joined.
       bool onlyCoordinatorJoined = activity.joinedUserIds.length == 1 && activity.joinedUserIds.contains(activity.coordinatorId) && activity.coordinatorId == appDataProvider.currentUser?.id;

       if (!onlyCoordinatorJoined && activity.joinedUserIds.any((uid) => uid != appDataProvider.currentUser?.id)) {
         showAppSnackBar(context, "You must pass the coordinator role to another participant before deleting this activity.", isError: true);
         return;
       }
    }

     _showConfirmationDialog(context,
      title: "Delete Activity?",
      content: "Are you sure you want to permanently delete this activity? This action cannot be undone.",
      confirmColor: Theme.of(context).colorScheme.error,
      onConfirm: () {
        appDataProvider.deleteActivity(activity.id);
        showAppSnackBar(context, "Activity deleted successfully.");
        // Pop twice if coming from detail view inside home, then create/edit
        int popCount = 0;
        Navigator.of(context).popUntil((_) => popCount++ >= (ModalRoute.of(context)?.settings.name == CreateEditActivityScreen ? 1:2) );
      }
    );
  }


  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormat = DateFormat('EEE, MMM d, yyyy');
    final appDataProvider = Provider.of<AppDataProvider>(context, listen: false);


    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Activity' : 'Create New Activity'),
        actions: [
          if (widget.isEditing)
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
              onPressed: _handleDeleteActivity,
              tooltip: "Delete Activity",
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Activity Details'),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Activity Name'),
                validator: (value) => value == null || value.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ActivityCategory>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: ActivityCategory.values.map((ActivityCategory category) {
                  return DropdownMenuItem<ActivityCategory>(
                    value: category,
                    child: Text(categoryToString(category)),
                  );
                }).toList(),
                onChanged: (ActivityCategory? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationDetailsController, // Rename controller variable
                decoration: const InputDecoration(labelText: 'Location Details (e.g., "Meet at the main fountain")'),
                validator: (value) => value == null || value.isEmpty ? 'Please enter location details' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (value) => value == null || value.isEmpty ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _maxUsersController,
                decoration: const InputDecoration(labelText: 'Max Users to Join'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter max users';
                  final num = int.tryParse(value);
                  if (num == null || num <= 0) return 'Must be a positive number';
                  if (widget.isEditing && num < _joinedUsers.length) return 'Cannot be less than current participants (${_joinedUsers.length})';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('Date & Time'),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(context, true),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Start Date'),
                        child: Text(_startDate != null ? dateFormat.format(_startDate!) : 'Select date'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickTime(context, true),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Start Time'),
                        child: Text(_startTime != null ? _startTime!.format(context) : 'Select time'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(context, false),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'End Date',
                           errorText: (_endDate != null && _startDate != null && _endDate!.isBefore(_startDate!)) ? 'End date before start' : null,
                        ),
                        child: Text(_endDate != null ? dateFormat.format(_endDate!) : 'Select date'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickTime(context, false),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'End Time'),
                        child: Text(_endTime != null ? _endTime!.format(context) : 'Select time'),
                      ),
                    ),
                  ),
                ],
              ),
               if (_startDate != null && _startTime != null && _endDate != null && _endTime != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Builder(builder: (context) {
                     final DateTime combinedStart = DateTime(_startDate!.year, _startDate!.month, _startDate!.day, _startTime!.hour, _startTime!.minute);
                     final DateTime combinedEnd = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, _endTime!.hour, _endTime!.minute);
                     if (combinedEnd.isBefore(combinedStart)) {
                       return Text("Error: End time is before start time.", style: TextStyle(color: Theme.of(context).colorScheme.error));
                     }
                     return Container();
                  }),
                ),

              const SizedBox(height: 24),
              _buildSectionTitle('Location'),
              InkWell(
                onTap: _selectLocationOnMap,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Activity Location Pin',
                    hintText: 'Tap to select on map',
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _selectedLocation != null
                              ? 'Lat: ${_selectedLocation!.latitude.toStringAsFixed(4)}, Lng: ${_selectedLocation!.longitude.toStringAsFixed(4)}'
                              : 'No location selected',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.map_outlined, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              if (_selectedLocation == null)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text('Location is required.', style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
                ),

              if (widget.isEditing && widget.activityToEdit != null) ...[
                const SizedBox(height: 24),
                _buildSectionTitle('Manage Participants (${_joinedUsers.length})'),
                if (_joinedUsers.isEmpty)
                  const Text('No users have joined this activity yet.')
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _joinedUsers.length,
                    itemBuilder: (context, index) {
                      final user = _joinedUsers[index];
                      // Coordinator cannot remove themselves via this list
                      if (user.id == widget.activityToEdit!.coordinatorId) {
                        return ListTile(
                          leading: const Icon(Icons.admin_panel_settings),
                          title: Text('${user.name} (Coordinator)'),
                        );
                      }
                      return ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(user.name),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                          onPressed: () => _handleDeleteUser(user.id),
                        ),
                      );
                    },
                  ),

                if (_joinedUsers.where((u) => u.id != appDataProvider.currentUser?.id).isNotEmpty) ...[ // Check if there are other users to pass to
                  const SizedBox(height: 24),
                  _buildSectionTitle('Pass Coordinator Role'),
                  DropdownButtonFormField<String>(
                    value: _selectedUserToPassCoordinator,
                    hint: const Text('Select a participant to become coordinator'),
                    items: _joinedUsers
                        .where((user) => user.id != widget.activityToEdit!.coordinatorId) // Can't pass to self
                        .map((UserModel user) {
                      return DropdownMenuItem<String>(
                        value: user.id,
                        child: Text(user.name),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedUserToPassCoordinator = newValue;
                      });
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('Pass Coordinator Role'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    onPressed: _selectedUserToPassCoordinator != null ? _handlePassCoordinator : null,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Note: If you delete the activity while participants are joined, you must pass the coordinator role first.",
                     style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ] else if (widget.activityToEdit!.joinedUserIds.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                    "No other participants to pass coordinator role to. You can delete the activity if you are the only one involved, or after removing other participants.",
                     style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ]
              ],

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: Text(widget.isEditing ? 'Save Changes' : 'Create Activity'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context, {
    required String title,
    required String content,
    required VoidCallback onConfirm,
    Color? confirmColor
  }) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: Text('Confirm', style: TextStyle(color: confirmColor ?? Theme.of(context).colorScheme.primary)),
              onPressed: () {
                onConfirm();
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }
}