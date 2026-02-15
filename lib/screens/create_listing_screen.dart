import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/listings_refresh_provider.dart';
import '../services/api_service.dart';
import '../services/image_upload_service.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final ApiService _api = ApiService();
  final ImageUploadService _uploadService = ImageUploadService();
  final ImagePicker _picker = ImagePicker();

  bool _isFree = false;
  String? _category;
  File? _pickedImage;
  String? _imageUrl;
  bool _isUploading = false;
  bool _isSubmitting = false;
  String? _error;

  static const _categories = [
    'furniture',
    'electronics',
    'books',
    'clothing',
    'kitchen',
    'other',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.of(context).pop(); // close bottom sheet

    try {
      final xfile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (xfile == null || !mounted) return;

      setState(() {
        _pickedImage = File(xfile.path);
        _imageUrl = null;
        _isUploading = true;
        _error = null;
      });

      final url = await _uploadService.uploadListingImage(File(xfile.path));
      if (mounted) {
        setState(() {
          _imageUrl = url;
          _isUploading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _error = 'Failed to add photo: ${e.toString().split('\n').first}';
        });
      }
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () => _pickImage(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () => _pickImage(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
  }

  void _removePhoto() {
    setState(() {
      _pickedImage = null;
      _imageUrl = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await _api.createListing(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        imageUrl: _imageUrl,
        price: _isFree ? null : double.tryParse(_priceController.text),
        isFree: _isFree,
        category: _category,
      );
      if (mounted) {
        context.read<ListingsRefreshProvider>().trigger();
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing posted!')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _isSubmitting = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Failed to create listing';
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post a listing'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Photo section
            const Text(
              'Photos',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            if (_pickedImage != null || _imageUrl != null)
              _buildPhotoPreview()
            else
              _buildAddPhotoButton(),
            const SizedBox(height: 20),

            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. Ikea desk, Calculus textbook',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Title is required';
                return null;
              },
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Condition, pickup details...',
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _isFree,
                  onChanged: (v) => setState(() {
                    _isFree = v ?? false;
                    if (_isFree) _priceController.clear();
                  }),
                ),
                const Text('Free'),
              ],
            ),
            if (!_isFree) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price (\$)',
                  hintText: '0.00',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (_isFree) return null;
                  if (v == null || v.trim().isEmpty) return 'Price required';
                  final n = double.tryParse(v);
                  if (n == null || n < 0) return 'Enter a valid price';
                  return null;
                },
              ),
            ],
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Select category')),
                ..._categories.map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c[0].toUpperCase() + c.substring(1)),
                    )),
              ],
              onChanged: (v) => setState(() => _category = v),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Post listing'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddPhotoButton() {
    return InkWell(
      onTap: _isUploading ? null : _showImageSourceSheet,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.grey[600]),
            const SizedBox(height: 8),
            Text(
              'Add photo',
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
            Text(
              'Gallery or camera',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPreview() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _isUploading
              ? Container(
                  height: 160,
                  color: Colors.grey[200],
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 8),
                        Text('Uploading...', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                )
              : _pickedImage != null
                  ? Image.file(
                      _pickedImage!,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : _imageUrl != null
                      ? Image.network(
                          _imageUrl!,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 160,
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image, size: 48),
                          ),
                        )
                      : const SizedBox.shrink(),
        ),
        if (!_isUploading)
          Positioned(
            top: 8,
            right: 8,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: _removePhoto,
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
