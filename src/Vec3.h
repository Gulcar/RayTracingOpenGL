#pragma once

#include <cmath>

class Vec3
{
public:
	float x, y, z;

	constexpr Vec3() = default;
	constexpr Vec3(float x, float y, float z)
		: x(x), y(y), z(z) {}

	friend Vec3 operator+(const Vec3& l, const Vec3& r)
	{
		return Vec3(
			l.x + r.x,
			l.y + r.y,
			l.z + r.z
		);
	}

	friend Vec3 operator-(const Vec3& l, const Vec3& r)
	{
		return Vec3(
			l.x - r.x,
			l.y - r.y,
			l.z - r.z
		);
	}

	friend Vec3 operator*(const Vec3& l, float s)
	{
		return Vec3(
			l.x * s,
			l.y * s,
			l.z * s
		);
	}

	friend Vec3 operator/(const Vec3& l, float s)
	{
		return Vec3(
			l.x / s,
			l.y / s,
			l.z / s
		);
	}

	friend Vec3 operator*(float s, const Vec3& r) { return r * s; }
	Vec3& operator+=(const Vec3& r) { return (*this = *this + r); }
	Vec3& operator-=(const Vec3& r) { return (*this = *this - r); }
	Vec3& operator*=(float s) { return (*this = *this * s); }
	Vec3& operator/=(float s) { return (*this = *this / s); }
	
	friend Vec3 operator-(const Vec3& v) { return Vec3(-v.x, -v.y, -v.z); }

	float Length()
	{
		return std::sqrt(x * x + y * y + z * z);
	}

	Vec3 Normalized()
	{
		float len = Length();
		return *this / len;
	}

	static Vec3 RotateX(const Vec3& v, float angle)
	{
		float sinA = sin(angle);
		float cosA = cos(angle);

		return Vec3(
			v.x,
			v.y * cosA - v.z * sinA,
			v.y * sinA + v.z * cosA
		);
	}

	static Vec3 RotateY(const Vec3& v, float angle)
	{
		float sinA = sin(angle);
		float cosA = cos(angle);

		return Vec3(
			v.x * cosA + v.z * sinA,
			v.y,
			-v.x * sinA + v.z * cosA
		);
	}

	static Vec3 Cross(const Vec3& a, const Vec3& b)
	{
		return Vec3(
			a.y * b.z - a.z * b.y,
			a.z * b.x - a.x * b.z,
			a.x * b.y - a.y * b.x
		);
	}

	static float Dot(const Vec3& a, const Vec3& b)
	{
		return a.x * b.x + a.y * b.y + a.z * b.z;
	}
};
